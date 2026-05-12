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

    // Check both directions for existing relationship
    const exist = db.prepare(
      'SELECT id, status FROM friendships WHERE (user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)'
    ).get(req.userId, target.id, target.id, req.userId);

    if (exist) {
      if (exist.status >= 1) return res.status(409).json({ message: '已是好友' });
      return res.status(409).json({ message: '已发送过请求，等待对方处理' });
    }

    db.prepare('INSERT INTO friendships (user_id, friend_id, status) VALUES (?,?,0)').run(req.userId, target.id);
    res.json({ message: '好友请求已发送' });
  } catch (e) { res.status(500).json({ message: '添加失败' }); }
});

router.get('/search', auth, (req, res) => {
  try {
    const { q } = req.query;
    if (!q || q.trim().length < 3) return res.json({ users: [] });
    const users = db.prepare(
      'SELECT id, phone, username FROM users WHERE phone LIKE ? AND is_active = 1 AND id != ? LIMIT 5'
    ).all(`%${q.trim()}%`, req.userId);
    res.json({ users });
  } catch (e) { res.status(500).json({ message: '搜索失败' }); }
});

router.get('/requests', auth, (req, res) => {
  try {
    const requests = db.prepare(`
      SELECT f.id, f.user_id, f.status, u.username, u.phone FROM friendships f
      JOIN users u ON f.user_id = u.id WHERE f.friend_id = ? AND f.status = 0
    `).all(req.userId);
    res.json({ requests });
  } catch (e) { res.status(500).json({ message: '获取请求失败' }); }
});

router.post('/respond', auth, (req, res) => {
  try {
    const { id, status, can_view_mood } = req.body;

    // Validate status
    const statusNum = parseInt(status, 10);
    if (statusNum !== 1 && statusNum !== -1) {
      return res.status(400).json({ message: '无效的状态值' });
    }

    // Only allow updating pending (status=0) requests
    const existing = db.prepare('SELECT status FROM friendships WHERE id = ? AND friend_id = ? AND status = 0')
      .get(id, req.userId);
    if (!existing) return res.status(404).json({ message: '请求不存在或已处理' });

    const expires = can_view_mood ? new Date(Date.now() + 7 * 86400000).toISOString() : null;
    db.prepare('UPDATE friendships SET status = ?, permission_expires_at = ? WHERE id = ? AND friend_id = ?')
      .run(statusNum, expires, id, req.userId);

    // If accepted, create reverse row for bidirectional friendship
    if (statusNum === 1) {
      const f = db.prepare('SELECT user_id FROM friendships WHERE id = ?').get(id);
      if (f) {
        const reverse = db.prepare(
          'SELECT id FROM friendships WHERE user_id = ? AND friend_id = ?'
        ).get(req.userId, f.user_id);
        if (!reverse) {
          db.prepare('INSERT INTO friendships (user_id, friend_id, status) VALUES (?,?,1)')
            .run(req.userId, f.user_id);
        }
      }
    }

    res.json({ message: '已处理' });
  } catch (e) { res.status(500).json({ message: '处理失败' }); }
});

router.get('/list', auth, (req, res) => {
  try {
    // Query both directions: friends where I'm the requester OR the receiver
    const friends = db.prepare(`
      SELECT f.id, f.friend_id, f.user_id, f.status, f.permission_expires_at, u.username, u.phone
      FROM friendships f JOIN users u ON (
        (f.friend_id = u.id AND f.user_id = ?) OR (f.user_id = u.id AND f.friend_id = ?)
      )
      WHERE (
        (f.user_id = ? AND f.status >= 1) OR (f.friend_id = ? AND f.status >= 1)
      )
    `).all(req.userId, req.userId, req.userId, req.userId);
    res.json({ friends });
  } catch (e) { res.status(500).json({ message: '获取好友列表失败' }); }
});

router.get('/:id/mood', auth, (req, res) => {
  try {
    // Check both directions for friendship with mood viewing permission
    const friend = db.prepare(`
      SELECT * FROM friendships WHERE
      ((user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?))
      AND status = 2 AND permission_expires_at > datetime('now')
    `).get(req.userId, req.params.id, req.params.id, req.userId);

    if (!friend) return res.status(403).json({ message: '无权查看或授权已过期' });

    const moods = db.prepare(
      "SELECT date, emotion_type, notes FROM moods WHERE user_id = ? AND date >= date('now','-3 days') ORDER BY date DESC"
    ).all(req.params.id);
    res.json({ moods });
  } catch (e) { res.status(500).json({ message: '获取心情失败' }); }
});

module.exports = router;
