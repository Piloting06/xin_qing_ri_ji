require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const cors = require('cors');
const { init: initDb } = require('./db');

const app = express();
const PORT = process.env.PORT || 3001;

async function start() {
  await initDb();

  app.use(helmet());
  app.use(cors({ origin: '*', credentials: true }));
  app.use(express.json());

  const registerLimiter = rateLimit({ windowMs: 60000, max: 3, message: { message: '注册太频繁，请稍后再试' } });
  const loginLimiter = rateLimit({ windowMs: 60000, max: 10, message: { message: '登录太频繁，请稍后再试' } });


  app.use('/api/auth/register', registerLimiter);
  app.use('/api/auth/login', loginLimiter);
  app.use('/api/auth', require('./routes/auth'));
  app.use('/api/weather', require('./routes/weather'));
  app.use('/api/mood', require('./routes/mood'));
  app.use('/api/checkin', require('./routes/checkin'));
  app.use('/api/friends', require('./routes/friends'));
  app.use('/api/treehole', require('./routes/treehole'));
  app.use('/api/capsule', require('./routes/capsule'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/city', require('./routes/city'));

// Admin panel static files
app.use('/admin', express.static(require('path').join(__dirname, 'admin')));
app.get('/admin', (_req, res) => res.sendFile(require('path').join(__dirname, 'admin', 'index.html')));

  app.get('/api/health', (_, res) => res.json({ status: 'ok', time: new Date().toISOString() }));

  app.use((err, _req, res, _next) => {
    console.error(err);
    res.status(500).json({ message: '服务器内部错误' });
  });

  app.listen(PORT, () => {
    console.log(`心晴日记 API running on port ${PORT}`);
  });
}

start();
