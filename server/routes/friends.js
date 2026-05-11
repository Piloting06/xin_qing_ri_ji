const express = require('express');
const auth = require('../middleware/auth');
const { db } = require('../db');
const router = express.Router();

router.post('/add', auth, (req, res) => {
  try {
    const { phone } = req.body;
    const target = db.prepare('SELECT id, username FROM users WHERE phone = ? AND is_active = 1').get(phone);
    if (!target) return res.status(404).json({ message: '未找到该用户' });
    if (target.id === req.userId) return res.status(400).json({ message: '不能添加自己' });
    const exist = db.prepare('SELECT id FROM friendships WHERE user_id = ? AND friend_id = ?').get(req.userId, target.id);
    if (exist) return res.status(409).json({ message: '已是好友或已发送请求' });
    db.prepare('INSERT INTO friendships (user_id, friend_id, status) VALUES (?,?,0)').run(req.userId, target.id);
    res.json({ message: '好友请求已发送' });
  } catch (e) { res.status(500).json({ message: '添加失败' }); }
});

router.get('/requests', auth, (_, res) => {
  const requests = db.prepare(`
    SELECT f.id, f.user_id, f.status, u.username, u.phone FROM friendships f
    JOIN users u ON f.user_id = u.id WHERE f.friend_id = ? AND f.status = 0
  `).all(req.userId);
  res.json({ requests });
});

router.post('/respond', auth, (req, res) => {
  try {
    const { id, status, can_view_mood } = req.body;
    const expires = can_view_mood ? new Date(Date.now() + 7 * 86400000).toISOString() : null;
    db.prepare('UPDATE friendships SET status = ?, permission_expires_at = ? WHERE id = ? AND friend_id = ?')
      .run(status, expires, id, req.userId);
    res.json({ message: '已处理' });
  } catch (e) { res.status(500).json({ message: '处理失败' }); }
});

router.get('/list', auth, (_, res) => {
  const friends = db.prepare(`
    SELECT f.id, f.friend_id, f.status, f.permission_expires_at, u.username, u.phone
    FROM friendships f JOIN users u ON f.friend_id = u.id
    WHERE f.user_id = ? AND f.status >= 1
  `).all(req.userId);
  res.json({ friends });
});

router.get('/:id/mood', auth, (req, res) => {
  const friend = db.prepare("SELECT * FROM friendships WHERE user_id = ? AND friend_id = ? AND status = 2 AND permission_expires_at > datetime('now')")
    .get(req.userId, req.params.id);
  if (!friend) return res.status(403).json({ message: '无权查看或授权已过期' });
  const moods = db.prepare("SELECT date, emotion_type, notes FROM moods WHERE user_id = ? AND date >= date('now','-3 days') ORDER BY date DESC")
    .all(req.params.id);
  res.json({ moods });
});

module.exports = router;
