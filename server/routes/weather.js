const express = require('express');
const auth = require('../middleware/auth');
const router = express.Router();

const cache = new Map();
const CACHE_TTL = 10 * 60 * 1000; // 10 min

const weatherCodes = {
  0: '晴天',
  1: '少云',
  2: '多云',
  3: '阴天',
  45: '雾',
  48: '雾凇',
  51: '小毛毛雨',
  53: '毛毛雨',
  55: '强毛毛雨',
  56: '冻毛毛雨',
  57: '强冻毛毛雨',
  61: '小雨',
  63: '中雨',
  65: '大雨',
  66: '冻雨',
  67: '强冻雨',
  71: '小雪',
  73: '中雪',
  75: '大雪',
  77: '雪粒',
  80: '小阵雨',
  81: '阵雨',
  82: '强阵雨',
  85: '小阵雪',
  86: '阵雪',
  95: '雷暴',
  96: '雷暴伴冰雹',
  99: '强雷暴伴冰雹',
};

function getCached(key) {
  const entry = cache.get(key);
  if (entry && Date.now() - entry.ts < CACHE_TTL) return entry.data;
  cache.delete(key);
  return null;
}

function setCache(key, data) {
  cache.set(key, { data, ts: Date.now() });
}

function normalizeIp(ip) {
  if (!ip) return '';
  return ip.replace(/^::ffff:/, '').trim();
}

function getClientIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  const firstForwarded = Array.isArray(forwarded) ? forwarded[0] : forwarded;
  const candidates = [
    firstForwarded?.split(',')[0],
    req.headers['x-real-ip'],
    req.ip,
    req.socket?.remoteAddress,
  ];
  return normalizeIp(candidates.find(Boolean));
}

function isPrivateIp(ip) {
  const v4 = ip.match(/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
  if (v4) {
    const a = Number(v4[1]);
    const b = Number(v4[2]);
    if (a === 10 || a === 127 || a === 0) return true;
    if (a === 172 && b >= 16 && b <= 31) return true;
    if (a === 192 && b === 168) return true;
    if (a === 169 && b === 254) return true;
    return false;
  }
  return ip === '::1' || ip.startsWith('fc') || ip.startsWith('fd') || ip.startsWith('fe80');
}

// Clean expired cache every 10 min
setInterval(() => {
  const now = Date.now();
  for (const [k, v] of cache) {
    if (now - v.ts > CACHE_TTL) cache.delete(k);
  }
}, 10 * 60 * 1000);

router.get('/', auth, async (req, res) => {
  try {
    const { lat, lon } = req.query;
    if (!lat || !lon) return res.status(400).json({ message: '缺少坐标参数' });

    const cacheKey = `weather:${lat}:${lon}`;
    const cached = getCached(cacheKey);
    if (cached) return res.json(cached);

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10000);

    const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max&timezone=Asia%2FShanghai&forecast_days=3`;
    let resp;
    try {
      resp = await fetch(url, { signal: controller.signal });
    } finally {
      clearTimeout(timeout);
    }

    if (!resp.ok) throw new Error(`Open-Meteo ${resp.status}`);
    const raw = await resp.json();
    const daily = raw.daily || {};
    const current = raw.current || {};

    const format = (i) => ({
      weather: weatherCodes[daily.weather_code?.[i]] || '未知',
      weather_code: daily.weather_code?.[i] || 0,
      temp_max: Math.round(daily.temperature_2m_max?.[i] || 0),
      temp_min: Math.round(daily.temperature_2m_min?.[i] || 0),
      rain_prob: daily.precipitation_probability_max?.[i] || 0,
      wind: Math.round(daily.wind_speed_10m_max?.[i] || 0),
    });

    const currentData = {
      weather: weatherCodes[current.weather_code] || weatherCodes[daily.weather_code?.[0]] || '未知',
      weather_code: current.weather_code ?? daily.weather_code?.[0] ?? 0,
      temp_current: current.temperature_2m == null ? null : Math.round(current.temperature_2m),
      feels_like: current.apparent_temperature == null ? null : Math.round(current.apparent_temperature),
      humidity: current.relative_humidity_2m == null ? null : Math.round(current.relative_humidity_2m),
      wind_current: current.wind_speed_10m == null ? null : Math.round(current.wind_speed_10m),
      observed_at: current.time || null,
    };

    const data = {
      current: currentData,
      today: { ...format(0), ...currentData },
      tomorrow: format(1),
      day_after: format(2),
    };
    setCache(cacheKey, data);
    res.json(data);
  } catch (e) {
    if (e.name === 'AbortError') {
      return res.status(504).json({ message: '天气服务超时，请重试' });
    }
    console.error('weather:', e.message);
    res.status(500).json({ message: '获取天气失败' });
  }
});

router.get('/reverse', auth, async (req, res) => {
  try {
    const { lat, lon } = req.query;
    const latitude = Number(lat);
    const longitude = Number(lon);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      return res.status(400).json({ message: '坐标格式不正确' });
    }
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      return res.status(400).json({ message: '坐标超出范围' });
    }

    const cacheKey = `reverse:${latitude.toFixed(3)}:${longitude.toFixed(3)}`;
    const cached = getCached(cacheKey);
    if (cached) return res.json(cached);

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8000);
    const url = `https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${latitude}&lon=${longitude}&accept-language=zh-CN`;
    let resp;
    try {
      resp = await fetch(url, {
        signal: controller.signal,
        headers: { 'User-Agent': 'xin-qing-ri-ji-weather/1.4.0' },
      });
    } finally {
      clearTimeout(timeout);
    }
    if (!resp.ok) throw new Error(`Nominatim ${resp.status}`);

    const raw = await resp.json();
    const address = raw.address || {};
    const city = address.city || address.town || address.village || address.county || '';
    const region = address.state || address.province || '';
    const country = address.country || '';
    if (!city && !region) {
      return res.json({ error: true, message: '无法解析当前位置城市，请手动选择城市' });
    }

    const data = { city, region, country };
    setCache(cacheKey, data);
    res.json(data);
  } catch (e) {
    res.json({ error: true, message: e.name === 'AbortError' ? '城市解析超时，请手动选择城市' : '城市解析失败，请手动选择城市' });
  }
});

// City search via Open-Meteo Geocoding (as Gaode requires API key)
router.get('/search', auth, async (req, res) => {
  try {
    const { q } = req.query;
    if (!q) return res.status(400).json({ message: '请输入城市名' });
    const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(q)}&count=10&language=zh&format=json`;
    const resp = await fetch(url);
    const raw = await resp.json();
    const cities = (raw.results || []).map(r => ({
      name: r.name || '',
      latitude: r.latitude,
      longitude: r.longitude,
      admin1: r.admin1 || '',
      country: r.country || '',
    }));
    res.json({ cities });
  } catch (e) {
    res.status(500).json({ message: '搜索失败' });
  }
});

// IP-based location
router.get('/location', auth, async (req, res) => {
  try {
    const ip = getClientIp(req);
    if (!ip || isPrivateIp(ip)) {
      return res.json({ error: true, message: '无法通过当前网络定位，请使用系统定位或手动选择城市' });
    }
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    const url = `http://ip-api.com/json/${encodeURIComponent(ip)}?lang=zh-CN`;
    let resp;
    try {
      resp = await fetch(url, { signal: controller.signal });
    } finally {
      clearTimeout(timeout);
    }
    const raw = await resp.json();
    if (raw.status === 'success' && raw.city && raw.lat != null && raw.lon != null) {
      res.json({
        lat: raw.lat,
        lon: raw.lon,
        city: raw.city || '',
        region: raw.regionName || '',
        country: raw.country || '',
      });
    } else {
      res.json({ error: true, message: raw.message || '无法获取城市信息' });
    }
  } catch (e) {
    res.json({ error: true, message: e.name === 'AbortError' ? '定位服务超时' : '定位服务不可用' });
  }
});

module.exports = router;
