const express = require('express');
const auth = require('../middleware/auth');
const { db } = require('../db');
const router = express.Router();

const BAD_WORDS = ['傻逼', '操你', '去死', '滚蛋', '废物', '垃圾', '妈的', '尼玛', '脑残', '白痴'];
function filter(text) {
  let filtered = text;
  for (const w of BAD_WORDS) {
    filtered = filtered.replace(new RegExp(w, 'g'), '**');
  }
  return filtered;
}

router.get('/', auth, (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = 20;
  const offset = (page - 1) * limit;
  const messages = db.prepare(
    'SELECT id, content, cloud_hugs, cloud_coffees, created_at FROM treehole_messages WHERE is_visible = 1 ORDER BY created_at DESC LIMIT ? OFFSET ?'
  ).all(limit, offset);
  // Mark own messages
  const ownIds = db.prepare('SELECT id FROM treehole_messages WHERE user_id = ?').all(req.userId).map(r => r.id);
  const result = messages.map(m => ({ ...m, is_own: ownIds.includes(m.id) }));
  res.json({ messages: result, page });
});

router.post('/', auth, (req, res) => {
  try {
    const { content } = req.body;
    if (!content || !content.trim()) return res.status(400).json({ message: '内容不能为空' });
    const today = new Date().toISOString().slice(0, 10);
    const count = db.prepare("SELECT COUNT(*) as cnt FROM treehole_messages WHERE user_id = ? AND created_at >= ?").get(req.userId, today).cnt;
    if (count >= 3) return res.status(429).json({ message: '今天已发3条，明天再来吧' });
    const filtered = filter(content.trim());
    db.prepare('INSERT INTO treehole_messages (user_id, content) VALUES (?,?)').run(req.userId, filtered);
    res.json({ message: '留言成功' });
  } catch (e) { res.status(500).json({ message: '留言失败' }); }
});

router.post('/:id/interact', auth, (req, res) => {
  try {
    const { interaction_type } = req.body;
    const msgId = req.params.id;
    const existing = db.prepare('SELECT id FROM treehole_interactions WHERE message_id = ? AND user_id = ? AND interaction_type = ?')
      .get(msgId, req.userId, interaction_type);
    if (existing) return res.status(409).json({ message: '你已经互动过了' });
    db.prepare('INSERT INTO treehole_interactions (message_id, user_id, interaction_type) VALUES (?,?,?)')
      .run(msgId, req.userId, interaction_type);
    const col = interaction_type === 'cloud_hug' ? 'cloud_hugs' : 'cloud_coffees';
    db.prepare(`UPDATE treehole_messages SET ${col} = ${col} + 1 WHERE id = ?`).run(msgId);
    res.json({ message: '互动成功' });
  } catch (e) { res.status(500).json({ message: '互动失败' }); }
});

module.exports = router;
