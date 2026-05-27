const express = require('express');
const auth = require('../middleware/auth');
const { db } = require('../db');
const router = express.Router();

// POST / — 新增一条心情记录（每次都是新记录，不覆盖）
router.post('/', auth, (req, res) => {
  try {
    const { date, emotion_type, emotion_tags, notes } = req.body;
    const result = db.prepare(
      'INSERT INTO moods (user_id, date, emotion_type, emotion_tags, notes) VALUES (?,?,?,?,?)'
    ).run(req.userId, date, emotion_type, emotion_tags || '', notes || '');
    res.json({ id: result.lastInsertRowid, message: '已保存' });
  } catch (e) { res.status(500).json({ message: '保存失败' }); }
});

// GET /?date=YYYY-MM-DD — 获取某天所有记录
router.get('/', auth, (req, res) => {
  try {
    const { date } = req.query;
    const moods = db.prepare(
      'SELECT * FROM moods WHERE user_id = ? AND date = ? ORDER BY created_at ASC'
    ).all(req.userId, date);
    res.json({ moods });
  } catch (e) { res.status(500).json({ message: '获取失败' }); }
});

// GET /all — 获取所有记录
router.get('/all', auth, (req, res) => {
  try {
    const moods = db.prepare(
      'SELECT * FROM moods WHERE user_id = ? ORDER BY date DESC, created_at DESC'
    ).all(req.userId);
    res.json({ moods });
  } catch (e) { res.status(500).json({ message: '获取失败' }); }
});

// DELETE /:id — 删除单条记录
router.delete('/:id', auth, (req, res) => {
  try {
    const { id } = req.params;
    const mood = db.prepare('SELECT id FROM moods WHERE id = ? AND user_id = ?').get(id, req.userId);
    if (!mood) return res.status(404).json({ message: '记录不存在' });
    db.prepare('DELETE FROM moods WHERE id = ?').run(id);
    res.json({ message: '已删除' });
  } catch (e) { res.status(500).json({ message: '删除失败' }); }
});

module.exports = router;
