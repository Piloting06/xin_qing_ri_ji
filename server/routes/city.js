const express = require('express');
const auth = require('../middleware/auth');
const { db } = require('../db');
const { containsSensitive } = require('../sensitive_words');
const router = express.Router();

// ── 情绪关键词库 ──
const MOOD_KEYWORDS = {
  warm: ['开心','幸福','美好','喜欢','温暖','治愈','爱','快乐','高兴','嘻嘻','哈哈','嘿嘿','真好','太棒了','好开心','满足','感恩','幸运','甜甜的','浪漫','心动','暖到了','被治愈了','今天真好','舒服','惬意','爽','nice','绝了','美滋滋','乐坏了','爱了'],
  sad: ['难过','伤心','哭了','孤独','失落','想哭','好累啊','想家了','心里空空的','没人懂','难受','委屈','泪目','破防了','绷不住了','emo','丧','好烦啊','不想说话','想一个人待着','撑不住了','熬不过去','好苦','心疼自己','低落','被伤到了','心碎','好难过啊'],
  anxious: ['焦虑','压力','累','崩溃','烦','卷','怎么办','好怕','担心','紧张','失眠','睡不着','扛不住','喘不过气','迷茫','不知道咋办','想逃','撑不下去了','一地鸡毛','焦头烂额','忙死了','头大','烦死了','emo了','想摆烂','躺平了','卷不动了'],
  calm: ['安静','想想','等待','希望','慢慢','放空','发呆','沉淀','静一静','会好的','没关系','随缘','算了','就这样吧','顺其自然','一切都会过去','慢慢来','不急','总会好的','看开了','想通了','心态平和','平常心'],
  excited: ['热闹','加油','冲','嗨','庆祝','好吃','太爽了','燃起来了','冲鸭','干就完了','今天必须搞','约起来','走起','躁起来','疯狂','太酷了','绝绝子','yyds','爱了爱了','起飞','芜湖','炸了','名场面'],
};

// ── 情绪分析 ──
function analyzeMood(comments) {
  if (comments.length < 5) return null;
  const counts = { warm: 0, sad: 0, anxious: 0, calm: 0, excited: 0 };
  let matched = 0;

  for (const c of comments) {
    const text = (c.content || '').toLowerCase();
    let hit = false;
    for (const [mood, keywords] of Object.entries(MOOD_KEYWORDS)) {
      for (const kw of keywords) {
        if (text.includes(kw)) {
          counts[mood]++;
          hit = true;
          break;
        }
      }
      if (hit) break; // 一条评论只计一个情绪
    }
    if (hit) matched++;
  }

  if (matched === 0) return null;

  // 找到最高频情绪
  let best = 'warm';
  let bestCount = 0;
  for (const [mood, count] of Object.entries(counts)) {
    if (count > bestCount) { best = mood; bestCount = count; }
  }

  const ratio = bestCount / matched;
  if (ratio < 0.3) return { mood: 'mixed', score: ratio };
  return { mood: best, score: ratio };
}

// ── CST 日期 ──
function cstDate(daysOffset = 0) {
  const d = new Date(Date.now() + 8 * 3600000 + daysOffset * 86400000);
  return d.toISOString().slice(0, 10);
}

// ── GET /stats — 所有城市评论数 + 情绪 ──
router.get('/stats', auth, (req, res) => {
  try {
    // 评论数统计
    const counts = db.prepare(`
      SELECT city_code, COUNT(*) as cnt FROM city_comments
      WHERE is_visible = 1
      GROUP BY city_code
    `).all();

    const stats = {};
    for (const row of counts) {
      // 拉该城市最近 50 条做情绪分析
      const recent = db.prepare(
        'SELECT content FROM city_comments WHERE city_code = ? AND is_visible = 1 ORDER BY created_at DESC LIMIT 50'
      ).all(row.city_code);
      const mood = analyzeMood(recent);

      stats[row.city_code] = { count: row.cnt };
      if (mood) {
        stats[row.city_code].mood = mood.mood;
        stats[row.city_code].mood_score = Math.round(mood.score * 100) / 100;
      }
    }

    res.json({ stats });
  } catch (e) { res.status(500).json({ message: '获取统计失败' }); }
});

// ── GET /comments — 某城市评论列表 ──
router.get('/comments', auth, (req, res) => {
  try {
    const cityCode = String(req.query.city || '').trim();
    if (!cityCode) return res.status(400).json({ message: '请指定城市' });

    const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
    const limit = 20;
    const offset = (page - 1) * limit;

    const comments = db.prepare(`
      SELECT id, content, likes,
             strftime('%Y-%m-%dT%H:%M:%SZ', created_at) AS created_at,
             CASE WHEN user_id = ? THEN 1 ELSE 0 END AS is_own
      FROM city_comments
      WHERE city_code = ? AND is_visible = 1
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    `).all(req.userId, cityCode, limit, offset);

    // 查当前用户是否已点赞
    if (comments.length > 0) {
      const ids = comments.map(c => c.id).join(',');
      const liked = db.prepare(
        `SELECT comment_id FROM city_comment_likes WHERE user_id = ? AND comment_id IN (${ids})`
      ).all(req.userId);
      const likedSet = new Set(liked.map(r => r.comment_id));
      for (const c of comments) {
        c.liked = likedSet.has(c.id);
      }
    }

    res.json({ comments, page });
  } catch (e) { res.status(500).json({ message: '获取评论失败' }); }
});

// ── POST /comments — 发布评论 ──
router.post('/comments', auth, (req, res) => {
  try {
    const cityCode = String(req.body.city_code || '').trim();
    const content = String(req.body.content || '').trim();

    if (!cityCode) return res.status(400).json({ message: '请指定城市' });
    if (!content) return res.status(400).json({ message: '内容不能为空' });
    if (content.length > 100) return res.status(400).json({ message: '最多 100 字' });
    if (containsSensitive(content)) {
      return res.status(400).json({ message: '内容里有不适合发布的词，改一下再发吧' });
    }

    // 速率限制：同城同用户每天 2 条
    const today = cstDate();
    const startMs = Date.parse(`${today}T00:00:00+08:00`);
    const startUtc = new Date(startMs).toISOString().slice(0, 19).replace('T', ' ');
    const endUtc = new Date(startMs + 86400000).toISOString().slice(0, 19).replace('T', ' ');
    const todayCount = db.prepare(
      'SELECT COUNT(*) as cnt FROM city_comments WHERE user_id = ? AND city_code = ? AND created_at >= ? AND created_at < ?'
    ).get(req.userId, cityCode, startUtc, endUtc).cnt;
    if (todayCount >= 2) {
      return res.status(429).json({ message: '今天在这个城市已经说过啦，明天再来吧' });
    }

    const result = db.prepare(
      'INSERT INTO city_comments (city_code, user_id, content) VALUES (?,?,?)'
    ).run(cityCode, req.userId, content);

    res.json({ id: result.lastInsertRowid, message: '足迹已留下' });
  } catch (e) { res.status(500).json({ message: '发布失败' }); }
});

// ── POST /comments/:id/like — 点赞 ──
router.post('/comments/:id/like', auth, (req, res) => {
  try {
    const commentId = req.params.id;
    const comment = db.prepare('SELECT id FROM city_comments WHERE id = ? AND is_visible = 1').get(commentId);
    if (!comment) return res.status(404).json({ message: '评论不存在' });

    const existing = db.prepare(
      'SELECT id FROM city_comment_likes WHERE comment_id = ? AND user_id = ?'
    ).get(commentId, req.userId);
    if (existing) return res.status(409).json({ message: '已经点过赞了' });

    db.prepare('INSERT INTO city_comment_likes (comment_id, user_id) VALUES (?,?)').run(commentId, req.userId);
    db.prepare('UPDATE city_comments SET likes = likes + 1 WHERE id = ?').run(commentId);
    res.json({ message: '已点赞' });
  } catch (e) { res.status(500).json({ message: '点赞失败' }); }
});

// ── DELETE /comments/:id — 删除评论 ──
router.delete('/comments/:id', auth, (req, res) => {
  try {
    const comment = db.prepare(
      'SELECT id, user_id FROM city_comments WHERE id = ? AND is_visible = 1'
    ).get(req.params.id);
    if (!comment) return res.status(404).json({ message: '评论不存在' });
    if (Number(comment.user_id) !== Number(req.userId)) {
      return res.status(403).json({ message: '不能删除别人的足迹' });
    }

    db.prepare('UPDATE city_comments SET is_visible = 0 WHERE id = ?').run(comment.id);
    res.json({ message: '足迹已删除' });
  } catch (e) { res.status(500).json({ message: '删除失败' }); }
});

// ── GET /comments/:id/replies — 获取回复 ──
router.get('/comments/:id/replies', auth, (req, res) => {
  try {
    const comment = db.prepare('SELECT id FROM city_comments WHERE id = ? AND is_visible = 1').get(req.params.id);
    if (!comment) return res.status(404).json({ message: '评论不存在' });

    const replies = db.prepare(`
      SELECT id, content, likes,
             strftime('%Y-%m-%dT%H:%M:%SZ', created_at) AS created_at,
             CASE WHEN user_id = ? THEN 1 ELSE 0 END AS is_own
      FROM city_comment_replies
      WHERE comment_id = ? AND is_visible = 1
      ORDER BY created_at ASC
    `).all(req.userId, req.params.id);

    res.json({ replies });
  } catch (e) { res.status(500).json({ message: '获取回复失败' }); }
});

// ── POST /comments/:id/replies — 回复评论 ──
router.post('/comments/:id/replies', auth, (req, res) => {
  try {
    const comment = db.prepare('SELECT id FROM city_comments WHERE id = ? AND is_visible = 1').get(req.params.id);
    if (!comment) return res.status(404).json({ message: '评论不存在' });

    const content = String(req.body.content || '').trim();
    if (!content) return res.status(400).json({ message: '回复不能为空' });
    if (content.length > 200) return res.status(400).json({ message: '回复最多 200 字' });
    if (containsSensitive(content)) {
      return res.status(400).json({ message: '回复里有不适合发布的词，改一下再发吧' });
    }

    const result = db.prepare(
      'INSERT INTO city_comment_replies (comment_id, user_id, content) VALUES (?,?,?)'
    ).run(req.params.id, req.userId, content);

    res.json({ id: result.lastInsertRowid, message: '回应已留下' });
  } catch (e) { res.status(500).json({ message: '回复失败' }); }
});

module.exports = router;
