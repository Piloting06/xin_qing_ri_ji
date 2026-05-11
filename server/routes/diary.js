const express = require('express');
const auth = require('../middleware/auth');
const { db } = require('../db');
const router = express.Router();

router.post('/', auth, (req, res) => {
  try {
    const { date, title, content, mood_id } = req.body;
    const existing = db.prepare('SELECT id FROM diaries WHERE user_id = ? AND date = ?').get(req.userId, date);
    if (existing) {
      db.prepare('UPDATE diaries SET title=?, content=?, mood_id=? WHERE id=?')
        .run(title || '', content || '', mood_id || null, existing.id);
      res.json({ id: existing.id });
    } else {
      const r = db.prepare('INSERT INTO diaries (user_id, date, title, content, mood_id) VALUES (?,?,?,?,?)')
        .run(req.userId, date, title || '', content || '', mood_id || null);
      res.json({ id: r.lastInsertRowid });
    }
  } catch (e) { res.status(500).json({ message: '保存失败' }); }
});

router.get('/', auth, (req, res) => {
  const { date } = req.query;
  const diary = db.prepare('SELECT * FROM diaries WHERE user_id = ? AND date = ?').get(req.userId, date);
  if (!diary) return res.status(404).json({ message: '暂无日记' });
  res.json(diary);
});

router.get('/all', auth, (_, res) => {
  const diaries = db.prepare('SELECT * FROM diaries WHERE user_id = ? ORDER BY date DESC').all(req.userId);
  res.json({ diaries });
});

router.get('/search', auth, (req, res) => {
  const { q } = req.query;
  const diaries = db.prepare("SELECT * FROM diaries WHERE user_id = ? AND (title LIKE ? OR content LIKE ?) ORDER BY date DESC")
    .all(req.userId, `%${q}%`, `%${q}%`);
  res.json({ diaries });
});

module.exports = router;
