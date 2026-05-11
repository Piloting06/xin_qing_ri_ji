const express = require('express');
const auth = require('../middleware/auth');
const { db } = require('../db');
const router = express.Router();

router.post('/', auth, (req, res) => {
  try {
    const { content, open_date } = req.body;
    if (!content || !open_date) return res.status(400).json({ message: '请填写完整' });
    db.prepare('INSERT INTO time_capsules (user_id, content, open_date) VALUES (?,?,?)').run(req.userId, content, open_date);
    res.json({ message: '胶囊已封存' });
  } catch (e) { res.status(500).json({ message: '创建失败' }); }
});

router.get('/list', auth, (_, res) => {
  const capsules = db.prepare('SELECT id, open_date, is_opened, created_at FROM time_capsules WHERE user_id = ? ORDER BY created_at DESC').all(req.userId);
  res.json({ capsules });
});

router.get('/:id', auth, (req, res) => {
  const capsule = db.prepare('SELECT * FROM time_capsules WHERE id = ? AND user_id = ?').get(req.params.id, req.userId);
  if (!capsule) return res.status(404).json({ message: '胶囊不存在' });
  db.prepare('UPDATE time_capsules SET is_opened = 1 WHERE id = ?').run(req.params.id);
  res.json(capsule);
});

module.exports = router;
