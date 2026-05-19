const express = require('express');
const auth = require('../middleware/auth');
const { db } = require('../db');
const router = express.Router();

router.post('/', auth, (req, res) => {
  try {
    const { date, emotion_type, emotion_tags, notes } = req.body;
    const existing = db.prepare('SELECT id FROM moods WHERE user_id = ? AND date = ?').get(req.userId, date);
    if (existing) {
      db.prepare('UPDATE moods SET emotion_type=?, emotion_tags=?, notes=? WHERE id=?')
        .run(emotion_type, emotion_tags || '', notes || '', existing.id);
      res.json({ id: existing.id, message: '已更新' });
    } else {
      const result = db.prepare('INSERT INTO moods (user_id, date, emotion_type, emotion_tags, notes) VALUES (?,?,?,?,?)')
        .run(req.userId, date, emotion_type, emotion_tags || '', notes || '');
      res.json({ id: result.lastInsertRowid, message: '已保存' });
    }
  } catch (e) { res.status(500).json({ message: '保存失败' }); }
});

router.get('/', auth, (req, res) => {
  try {
    const { date } = req.query;
    const mood = db.prepare('SELECT * FROM moods WHERE user_id = ? AND date = ?').get(req.userId, date);
    if (!mood) return res.status(404).json({ message: '暂无记录' });
    res.json(mood);
  } catch (e) { res.status(500).json({ message: '获取失败' }); }
});

router.get('/all', auth, (req, res) => {
  try {
    const moods = db.prepare('SELECT * FROM moods WHERE user_id = ? ORDER BY date DESC').all(req.userId);
    res.json({ moods });
  } catch (e) { res.status(500).json({ message: '获取失败' }); }
});

module.exports = router;
