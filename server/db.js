const initSqlJs = require('sql.js');
const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(__dirname, 'xinqingriji.db');
let db = null;

function saveDb() {
  if (db) {
    const data = db.export();
    fs.writeFileSync(DB_PATH, Buffer.from(data));
  }
}

function exec(sql) {
  db.exec(sql);
  saveDb();
}

// Helper to get last insert rowid
function getLastId() {
  const r = db.exec('SELECT last_insert_rowid() as id');
  return r[0]?.values?.[0]?.[0] || 0;
}

// Wrapper mimicking better-sqlite3 API
function prepare(sql) {
  return {
    run: (...params) => {
      db.run(sql, params);
      saveDb();
      return { lastInsertRowid: getLastId(), changes: db.getRowsModified() };
    },
    get: (...params) => {
      const stmt = db.prepare(sql);
      if (params.length > 0) stmt.bind(params);
      let result = null;
      if (stmt.step()) result = stmt.getAsObject();
      stmt.free();
      return result;
    },
    all: (...params) => {
      const stmt = db.prepare(sql);
      if (params.length > 0) stmt.bind(params);
      const results = [];
      while (stmt.step()) results.push(stmt.getAsObject());
      stmt.free();
      return results;
    }
  };
}

async function init() {
  const SQL = await initSqlJs();
  if (fs.existsSync(DB_PATH)) {
    const buffer = fs.readFileSync(DB_PATH);
    db = new SQL.Database(buffer);
  } else {
    db = new SQL.Database();
  }

  db.run('PRAGMA foreign_keys = ON');

  const tables = [
    `CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      phone TEXT UNIQUE NOT NULL,
      username TEXT NOT NULL,
      password_hash TEXT NOT NULL,
      security_question_type TEXT,
      security_question TEXT,
      security_answer_hash TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      is_active INTEGER DEFAULT 1,
      deleted_at TEXT
    )`,
    `CREATE TABLE IF NOT EXISTS moods (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      emotion_type INTEGER NOT NULL,
      emotion_tags TEXT,
      notes TEXT,
      weather_code TEXT,
      weather_temp_max REAL,
      weather_temp_min REAL,
      weather_rain_prob INTEGER,
      ai_response TEXT,
      poem_id INTEGER,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS mood_comments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      mood_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      content TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now')),
      deleted_at TEXT,
      FOREIGN KEY (mood_id) REFERENCES moods(id),
      FOREIGN KEY (user_id) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS diaries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      title TEXT,
      content TEXT,
      mood_id INTEGER,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS checkins (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      consecutive_days INTEGER DEFAULT 0,
      card_content TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS friendships (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      friend_id INTEGER NOT NULL,
      status INTEGER DEFAULT 0,
      permission_expires_at TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (friend_id) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS friend_notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sender_id INTEGER NOT NULL,
      receiver_id INTEGER NOT NULL,
      content TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (sender_id) REFERENCES users(id),
      FOREIGN KEY (receiver_id) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS treehole_messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      content TEXT NOT NULL,
      cloud_hugs INTEGER DEFAULT 0,
      cloud_coffees INTEGER DEFAULT 0,
      is_visible INTEGER DEFAULT 1,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS treehole_interactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      message_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      interaction_type TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now')),
      UNIQUE(message_id, user_id, interaction_type)
    )`,
    `CREATE TABLE IF NOT EXISTS time_capsules (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      content TEXT NOT NULL,
      open_date TEXT NOT NULL,
      is_opened INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS poems (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      poet TEXT NOT NULL,
      dynasty TEXT,
      content TEXT NOT NULL,
      emotion_type INTEGER,
      weather_type TEXT,
      quote_line TEXT
    )`,
    `CREATE TABLE IF NOT EXISTS push_cache (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      push_type TEXT NOT NULL,
      content TEXT NOT NULL,
      generated_at TEXT,
      is_sent INTEGER DEFAULT 0
    )`,
    `CREATE TABLE IF NOT EXISTS treehole_comments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      message_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      content TEXT NOT NULL,
      is_visible INTEGER DEFAULT 1,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (message_id) REFERENCES treehole_messages(id),
      FOREIGN KEY (user_id) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS sensitive_words (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      word TEXT UNIQUE NOT NULL,
      created_at TEXT DEFAULT (datetime('now'))
    )`,
    `CREATE TABLE IF NOT EXISTS admin_users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now'))
    )`,
    `CREATE TABLE IF NOT EXISTS admin_token_blacklist (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      token_hash TEXT UNIQUE NOT NULL,
      expired_at TEXT NOT NULL
    )`,
    `CREATE TABLE IF NOT EXISTS admin_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      admin_id INTEGER NOT NULL,
      action TEXT NOT NULL,
      target_type TEXT,
      target_id INTEGER,
      detail TEXT,
      created_at TEXT DEFAULT (datetime('now'))
    )`,
  ];

  for (const sql of tables) {
    db.run(sql);
  }

  const userColumns = db.exec('PRAGMA table_info(users)')[0]?.values?.map((row) => row[1]) || [];
  if (!userColumns.includes('deleted_at')) {
    db.run('ALTER TABLE users ADD COLUMN deleted_at TEXT');
  }

  saveDb();
  console.log('Database initialized');
}

module.exports = { db: { exec, prepare, saveDb }, init };
