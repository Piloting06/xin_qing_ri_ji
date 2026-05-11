const express = require('express');
const auth = require('../middleware/auth');
const router = express.Router();

const cache = new Map();
const CACHE_TTL = 10 * 60 * 1000; // 10 min

function getCached(key) {
  const entry = cache.get(key);
  if (entry && Date.now() - entry.ts < CACHE_TTL) return entry.data;
  cache.delete(key);
  return null;
}

function setCache(key, data) {
  cache.set(key, { data, ts: Date.now() });
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

    const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max&timezone=Asia%2FShanghai&forecast_days=3`;
    const resp = await fetch(url, { signal: controller.signal });
    clearTimeout(timeout);

    if (!resp.ok) throw new Error(`Open-Meteo ${resp.status}`);
    const raw = await resp.json();
    const daily = raw.daily || {};

    const weatherCodes = {
      0: '晴天', 1: '少云', 2: '多云', 3: '阴天',
      45: '雾', 48: '雾凇',
      51: '小雨', 53: '中雨', 55: '大雨',
      61: '小雪', 63: '中雪', 65: '大雪',
      71: '雨夹雪', 80: '阵雨', 95: '雷暴',
    };

    const format = (i) => ({
      weather: weatherCodes[daily.weather_code?.[i]] || '未知',
      weather_code: daily.weather_code?.[i] || 0,
      temp_max: Math.round(daily.temperature_2m_max?.[i] || 0),
      temp_min: Math.round(daily.temperature_2m_min?.[i] || 0),
      rain_prob: daily.precipitation_probability_max?.[i] || 0,
      wind: Math.round(daily.wind_speed_10m_max?.[i] || 0),
    });

    const data = { today: format(0), tomorrow: format(1), day_after: format(2) };
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
    const ip = req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.ip;
    const url = `https://ip-api.com/json/${ip}?lang=zh-CN`;
    const resp = await fetch(url);
    const raw = await resp.json();
    if (raw.status === 'success') {
      res.json({
        lat: raw.lat,
        lon: raw.lon,
        city: raw.city || '',
        region: raw.regionName || '',
        country: raw.country || '',
      });
    } else {
      res.json({ lat: 39.9042, lon: 116.4074, city: '北京' });
    }
  } catch (_) {
    res.json({ lat: 39.9042, lon: 116.4074, city: '北京' });
  }
});

module.exports = router;
