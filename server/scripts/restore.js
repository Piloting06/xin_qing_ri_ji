// 数据库恢复脚本：用备份覆盖当前数据库
// 用法：
//   1. pm2 stop xinqingriji          # 先停服务，避免内存态覆盖恢复结果
//   2. node scripts/restore.js backups/xinqingriji-20260828-0900.db
//   3. pm2 start xinqingriji
const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(__dirname, '..', 'xinqingriji.db');
const src = process.argv[2];

if (!src) {
  // 不带参数时列出可用备份
  const dir = path.join(__dirname, '..', 'backups');
  if (fs.existsSync(dir)) {
    const files = fs.readdirSync(dir).filter((f) => f.endsWith('.db')).sort().reverse();
    console.log('可用备份（新→旧）：');
    for (const f of files) console.log('  backups/' + f);
  } else {
    console.log('没有找到 backups 目录');
  }
  console.log('\n用法: node scripts/restore.js <备份文件路径>');
  process.exit(1);
}

const srcPath = path.resolve(src);
if (!fs.existsSync(srcPath)) {
  console.error('备份文件不存在: ' + srcPath);
  process.exit(1);
}

// 恢复前把当前库也留一份，防止误操作无法回退
if (fs.existsSync(DB_PATH)) {
  const safety = DB_PATH + '.before-restore-' + Date.now();
  fs.copyFileSync(DB_PATH, safety);
  console.log('当前数据库已留底: ' + path.basename(safety));
}

fs.copyFileSync(srcPath, DB_PATH);
// 清掉可能残留的临时/WAL 文件
for (const suffix of ['.tmp', '-wal', '-shm']) {
  const f = DB_PATH + suffix;
  if (fs.existsSync(f)) fs.unlinkSync(f);
}
console.log('已恢复: ' + srcPath + ' → ' + DB_PATH);
console.log('请执行: pm2 start xinqingriji');
