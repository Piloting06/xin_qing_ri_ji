const express = require('express');
const auth = require('../middleware/auth');
const { db } = require('../db');
const router = express.Router();

router.post('/', auth, (req, res) => {
  try {
    const today = new Date().toISOString().slice(0, 10);
    const existing = db.prepare('SELECT id FROM checkins WHERE user_id = ? AND date = ?').get(req.userId, today);
    if (existing) return res.json({ consecutive_days: 0, message: '今天已签到' });
    const yesterday = new Date(Date.now() - 86400000).toISOString().slice(0, 10);
    const prev = db.prepare('SELECT consecutive_days FROM checkins WHERE user_id = ? AND date = ?').get(req.userId, yesterday);
    const consecutive = (prev?.consecutive_days || 0) + 1;
    db.prepare('INSERT INTO checkins (user_id, date, consecutive_days) VALUES (?,?,?)').run(req.userId, today, consecutive);
    res.json({ consecutive_days: consecutive, message: '签到成功' });
  } catch (e) { res.status(500).json({ message: '签到失败' }); }
});

router.get('/status', auth, (_, res) => {
  const today = new Date().toISOString().slice(0, 10);
  const todayCheckin = db.prepare('SELECT * FROM checkins WHERE user_id = ? AND date = ?').get(req.userId, today);
  res.json({ checked_in: !!todayCheckin, consecutive_days: todayCheckin?.consecutive_days || 0 });
});

router.get('/card/today', auth, (_, res) => {
  res.json({ date: new Date().toISOString().slice(0, 10), card: null, message: '卡片功能即将上线' });
});

module.exports = router;
