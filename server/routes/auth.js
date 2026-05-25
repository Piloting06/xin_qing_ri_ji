const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { db } = require('../db');
const auth = require('../middleware/auth');
const { sendSms } = require('../sms');
const router = express.Router();

router.post('/register', (req, res) => {
  try {
    const { password, security_question_type, security_question, security_answer } = req.body;
    const phone = String(req.body.phone || '').trim();
    if (!/^1\d{10}$/.test(phone) || !password) {
      return res.status(400).json({ message: '请输入正确的手机号' });
    }
    if (password.length < 6) {
      return res.status(400).json({ message: '密码至少6位' });
    }
    const existing = db.prepare('SELECT id, is_active FROM users WHERE phone = ?').get(phone);
    if (existing && Number(existing.is_active) === 1) {
      return res.status(409).json({ message: '该手机号已注册' });
    }
    if (existing) {
      db.prepare('UPDATE users SET phone = ?, is_active = 0, deleted_at = COALESCE(deleted_at, datetime(\'now\')) WHERE id = ?')
        .run(`deleted_${existing.id}_${Date.now()}_${phone}`, existing.id);
    }
    const hash = bcrypt.hashSync(password, 10);
    let answerHash = null;
    if (security_answer) {
      answerHash = bcrypt.hashSync(security_answer, 10);
    }
    const result = db.prepare(
      'INSERT INTO users (phone, username, password_hash, security_question_type, security_question, security_answer_hash) VALUES (?, ?, ?, ?, ?, ?)'
    ).run(phone, '用户' + phone.slice(-4), hash, security_question_type || null, security_question || null, answerHash);
    const token = jwt.sign({ userId: result.lastInsertRowid }, process.env.JWT_SECRET, { expiresIn: '30d' });
    res.json({ token, display_name: '用户' + phone.slice(-4) });
  } catch (e) {
    console.error('register:', e.message);
    res.status(500).json({ message: '注册失败' });
  }
});

router.post('/login', (req, res) => {
  try {
    const phone = String(req.body.phone || '').trim();
    const { password } = req.body;
    const user = db.prepare('SELECT * FROM users WHERE phone = ? AND is_active = 1 AND deleted_at IS NULL').get(phone);
    if (!user) return res.status(401).json({ message: '账号不存在' });
    if (!bcrypt.compareSync(password, user.password_hash)) {
      return res.status(401).json({ message: '密码错误' });
    }
    const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: '30d' });
    res.json({ token, display_name: user.username });
  } catch (e) {
    console.error('login:', e.message);
    res.status(500).json({ message: '登录失败' });
  }
});

router.post('/change-password', auth, (req, res) => {
  try {
    const { old_password, new_password } = req.body;
    const user = db.prepare('SELECT password_hash FROM users WHERE id = ?').get(req.userId);
    if (!bcrypt.compareSync(old_password, user.password_hash)) {
      return res.status(400).json({ message: '当前密码错误' });
    }
    const hash = bcrypt.hashSync(new_password, 10);
    db.prepare('UPDATE users SET password_hash = ? WHERE id = ?').run(hash, req.userId);
    res.json({ message: '密码已更改' });
  } catch (e) {
    res.status(500).json({ message: '修改失败' });
  }
});

router.post('/change-username', auth, (req, res) => {
  try {
    const { username } = req.body;
    if (!username || !username.trim()) {
      return res.status(400).json({ message: '名字不能为空' });
    }
    db.prepare('UPDATE users SET username = ? WHERE id = ?').run(username.trim(), req.userId);
    res.json({ message: '名字已更新' });
  } catch (e) {
    res.status(500).json({ message: '修改失败' });
  }
});

router.post('/delete-account', auth, (req, res) => {
  try {
    const user = db.prepare('SELECT id, phone FROM users WHERE id = ? AND is_active = 1').get(req.userId);
    if (!user) return res.status(404).json({ message: '账号不存在或已注销' });

    const releasedPhone = `deleted_${user.id}_${Date.now()}_${user.phone}`;
    db.prepare('UPDATE users SET phone = ?, is_active = 0, deleted_at = datetime(\'now\') WHERE id = ?')
      .run(releasedPhone, req.userId);
    db.prepare('DELETE FROM friendships WHERE (user_id = ? OR friend_id = ?) AND status IN (0, 1)')
      .run(req.userId, req.userId);
    res.json({ message: '账号已注销' });
  } catch (e) {
    res.status(500).json({ message: '注销失败' });
  }
});

// ── SMS & password reset ──

router.post('/send-sms-code', (req, res) => {
  try {
    const phone = String(req.body.phone || '').trim();
    if (!/^1[3-9]\d{9}$/.test(phone)) {
      return res.status(400).json({ message: '手机号格式错误' });
    }
    const code = String(Math.floor(100000 + Math.random() * 900000));
    db.prepare('INSERT INTO sms_codes (phone, code, expires_at) VALUES (?, ?, datetime(\'now\', \'+5 minutes\'))')
      .run(phone, code);
    sendSms(phone, code).catch(e => console.error('SMS send error:', e.message));
    res.json({ message: '验证码已发送' });
  } catch (e) {
    console.error('send-sms-code:', e.message);
    res.status(500).json({ message: '发送失败' });
  }
});

router.post('/reset-password', (req, res) => {
  try {
    const phone = String(req.body.phone || '').trim();
    const { code, new_password } = req.body;
    if (!new_password || new_password.length < 6) {
      return res.status(400).json({ message: '密码至少6位' });
    }
    const row = db.prepare(
      'SELECT id FROM sms_codes WHERE phone = ? AND code = ? AND expires_at > datetime(\'now\') AND used = 0'
    ).get(phone, code);
    if (!row) {
      return res.status(400).json({ message: '验证码错误或已过期' });
    }
    const hash = bcrypt.hashSync(new_password, 10);
    db.prepare('UPDATE users SET password_hash = ? WHERE phone = ? AND is_active = 1').run(hash, phone);
    db.prepare('UPDATE sms_codes SET used = 1 WHERE id = ?').run(row.id);
    res.json({ message: '密码已重置' });
  } catch (e) {
    console.error('reset-password:', e.message);
    res.status(500).json({ message: '重置失败' });
  }
});

module.exports = router;
