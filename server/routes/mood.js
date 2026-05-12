const express = require('express');
const auth = require('../middleware/auth');
const { db } = require('../db');
const router = express.Router();

router.post('/', auth, (req, res) => {
  try {
    const { date, emotion_type, emotion_tags, notes, ai_response, photos } = req.body;
    const existing = db.prepare('SELECT id FROM moods WHERE user_id = ? AND date = ?').get(req.userId, date);
    if (existing) {
      db.prepare('UPDATE moods SET emotion_type=?, emotion_tags=?, notes=?, ai_response=?, photos=? WHERE id=?')
        .run(emotion_type, emotion_tags || '', notes || '', ai_response || '', photos || '', existing.id);
      res.json({ id: existing.id, message: '已更新' });
    } else {
      const result = db.prepare('INSERT INTO moods (user_id, date, emotion_type, emotion_tags, notes, ai_response, photos) VALUES (?,?,?,?,?,?,?)')
        .run(req.userId, date, emotion_type, emotion_tags || '', notes || '', ai_response || '', photos || '');
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

router.post('/ai-respond', auth, async (req, res) => {
  try {
    const { emotion_type, notes, weather_code } = req.body;
    const emotionLabels = ['', '开心', '平静', '难过', '生气', '焦虑', '疲惫', '期待', '思念'];
    const label = emotionLabels[emotion_type] || '复杂';
    const prompt = `用户现在感到${label}。天气是${weather_code || '未知'}。用户写下了："${notes || '无'}"。请用温柔的中文回应2-3句话，像朋友一样，不要指责，不要说教。`;
    const resp = await fetch('https://api.deepseek.com/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.DEEPSEEK_API_KEY}`,
      },
      body: JSON.stringify({
        model: 'deepseek-chat',
        messages: [{ role: 'user', content: prompt }],
        max_tokens: 200,
        temperature: 0.8,
      }),
      signal: AbortSignal.timeout(15000),
    });
    const data = await resp.json();
    const reply = data.choices?.[0]?.message?.content || '今天的一切都会过去的，我在这里陪着你。';
    res.json({ reply });
  } catch (e) { res.json({ reply: '今天的一切都会过去的，我在这里陪着你。' }); }
});

module.exports = router;
