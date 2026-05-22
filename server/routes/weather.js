const express = require('express');
const auth = require('../middleware/auth');
const router = express.Router();

const OPEN_METEO_BASE = 'https://api.open-meteo.com/v1/forecast';
const CACHE_TTL = 10 * 60 * 1000;

const cache = new Map();

function getCached(key) {
  const entry = cache.get(key);
  if (entry && Date.now() - entry.time < CACHE_TTL) return entry.data;
  cache.delete(key);
  return null;
}
function setCache(key, data) {
  cache.set(key, { data, time: Date.now() });
}

// WMO 天气码 → 我们的内部 weather_code
function mapWmoWeather(code) {
  const c = Number(code);
  if (c === 0) return { weather: '晴', code: 0 };
  if (c === 1) return { weather: '少云', code: 1 };
  if (c === 2) return { weather: '多云', code: 2 };
  if (c === 3) return { weather: '阴', code: 3 };
  if (c === 45 || c === 48) return { weather: '雾', code: 45 };
  if (c === 51) return { weather: '小毛毛雨', code: 51 };
  if (c === 53) return { weather: '毛毛雨', code: 53 };
  if (c === 55) return { weather: '大毛毛雨', code: 55 };
  if (c === 56 || c === 57) return { weather: '冻雨', code: 66 };
  if (c === 61) return { weather: '小雨', code: 61 };
  if (c === 63) return { weather: '中雨', code: 63 };
  if (c === 65) return { weather: '大雨', code: 65 };
  if (c === 66 || c === 67) return { weather: '冻雨', code: 66 };
  if (c === 71) return { weather: '小雪', code: 71 };
  if (c === 73) return { weather: '中雪', code: 73 };
  if (c === 75) return { weather: '大雪', code: 75 };
  if (c === 77) return { weather: '小雪', code: 71 };
  if (c === 80 || c === 81) return { weather: '阵雨', code: 80 };
  if (c === 82) return { weather: '强阵雨', code: 82 };
  if (c === 85 || c === 86) return { weather: '阵雪', code: 85 };
  if (c === 95) return { weather: '雷阵雨', code: 95 };
  if (c === 96 || c === 99) return { weather: '强雷阵雨', code: 96 };
  return { weather: '晴', code: 0 };
}

async function fetchOpenMeteo(url) {
  const https = require('https');
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try { resolve(JSON.parse(data)); }
        catch (e) { reject(e); }
      });
    }).on('error', reject);
  });
}

router.get('/', auth, async (req, res) => {
  try {
    let lat = parseFloat(req.query.lat);
    let lon = parseFloat(req.query.lon);
    if (isNaN(lat) || isNaN(lon)) return res.status(400).json({ message: '缺少经纬度参数' });

    const locKey = `${lat.toFixed(2)},${lon.toFixed(2)}`;
    const cached = getCached(locKey);
    if (cached) return res.json(cached);

    const params = new URLSearchParams({
      latitude: lat.toFixed(4),
      longitude: lon.toFixed(4),
      current: 'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
      daily: 'temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max,sunrise,sunset,wind_speed_10m_max',
      forecast_days: '3',
      timezone: 'Asia/Shanghai',
    });

    const data = await fetchOpenMeteo(`${OPEN_METEO_BASE}?${params}`);
    if (!data.current || !data.daily) return res.status(502).json({ message: '获取天气失败' });

    const current = data.current;
    const mapped = mapWmoWeather(current.weather_code);

    const result = {
      current: {
        weather: mapped.weather,
        weather_code: mapped.code,
        temp_current: Math.round(current.temperature_2m),
        feels_like: Math.round(current.apparent_temperature || current.temperature_2m),
        humidity: current.relative_humidity_2m ?? null,
        wind_current: current.wind_speed_10m ?? null,
        observed_at: current.time ? `${current.time}:00` : null,
      },
      today: data.daily.time.length > 0 ? formatDay(data.daily, 0) : {},
      tomorrow: data.daily.time.length > 1 ? formatDay(data.daily, 1) : {},
      day_after: data.daily.time.length > 2 ? formatDay(data.daily, 2) : {},
    };

    setCache(locKey, result);
    res.json(result);
  } catch (e) {
    console.error('weather:', e.message);
    res.status(502).json({ message: '获取天气失败' });
  }
});

function formatDay(daily, i) {
  const mapped = mapWmoWeather(daily.weather_code[i]);
  return {
    weather: mapped.weather,
    weather_code: mapped.code,
    temp_max: Math.round(daily.temperature_2m_max[i]),
    temp_min: Math.round(daily.temperature_2m_min[i]),
    sunrise: daily.sunrise?.[i] ? daily.sunrise[i].split('T')[1] : null,
    sunset: daily.sunset?.[i] ? daily.sunset[i].split('T')[1] : null,
    precip_prob: daily.precipitation_probability_max?.[i] ?? null,
    wind_speed: daily.wind_speed_10m_max?.[i] ?? null,
  };
}

// IP 定位（仅用 ip-api.com，不依赖任何 key）
router.get('/location', async (req, res) => {
  try {
    const http = require('http');
    http.get('http://ip-api.com/json/?fields=status,lat,lon,city,regionName,country', (resp) => {
      let d = ''; resp.on('data', c => d += c); resp.on('end', () => {
        try {
          const j = JSON.parse(d);
          if (j.status === 'success') {
            res.json({ lat: j.lat, lon: j.lon, city: j.city, region: j.regionName, country: j.country });
          } else {
            res.json({ lat: null, lon: null, city: '未知' });
          }
        } catch (_) { res.json({ lat: null, lon: null, city: '未知' }); }
      });
    }).on('error', () => res.json({ lat: null, lon: null, city: '未知' }));
  } catch (_) { res.json({ lat: null, lon: null, city: '未知' }); }
});

module.exports = router;
