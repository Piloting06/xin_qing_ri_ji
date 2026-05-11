const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { db } = require('../db');
const auth = require('../middleware/auth');
const router = express.Router();

router.post('/register', (req, res) => {
  try {
    const { phone, password, security_question_type, security_question, security_answer } = req.body;
    if (!phone || !password || phone.length < 11) {
      return res.status(400).json({ message: '请输入正确的手机号' });
    }
    if (password.length < 6) {
      return res.status(400).json({ message: '密码至少6位' });
    }
    const existing = db.prepare('SELECT id FROM users WHERE phone = ?').get(phone);
    if (existing) {
      return res.status(409).json({ message: '该手机号已注册' });
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
    const { phone, password } = req.body;
    const user = db.prepare('SELECT * FROM users WHERE phone = ? AND is_active = 1').get(phone);
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
    db.prepare('UPDATE users SET is_active = 0 WHERE id = ?').run(req.userId);
    res.json({ message: '账号已注销' });
  } catch (e) {
    res.status(500).json({ message: '注销失败' });
  }
});

module.exports = router;
