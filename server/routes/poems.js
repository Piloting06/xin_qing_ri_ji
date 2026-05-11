const express = require('express');
const auth = require('../middleware/auth');
const { db } = require('../db');
const router = express.Router();

// Seed 20 classic poems on first run
const seedPoems = [
  { title: '将进酒', poet: '李白', dynasty: '唐', content: '人生得意须尽欢，莫使金樽空对月。天生我材必有用，千金散尽还复来。', emotion_type: 1, weather_type: 'sunny', quote_line: '天生我材必有用，千金散尽还复来。' },
  { title: '静夜思', poet: '李白', dynasty: '唐', content: '床前明月光，疑是地上霜。举头望明月，低头思故乡。', emotion_type: 8, weather_type: 'sunny', quote_line: '举头望明月，低头思故乡。' },
  { title: '声声慢', poet: '李清照', dynasty: '宋', content: '寻寻觅觅，冷冷清清，凄凄惨惨戚戚。乍暖还寒时候，最难将息。', emotion_type: 3, weather_type: 'cloudy', quote_line: '这次第，怎一个愁字了得！' },
  { title: '定风波', poet: '苏轼', dynasty: '宋', content: '莫听穿林打叶声，何妨吟啸且徐行。竹杖芒鞋轻胜马，谁怕？一蓑烟雨任平生。', emotion_type: 2, weather_type: 'rain', quote_line: '回首向来萧瑟处，归去，也无风雨也无晴。' },
  { title: '春望', poet: '杜甫', dynasty: '唐', content: '国破山河在，城春草木深。感时花溅泪，恨别鸟惊心。', emotion_type: 5, weather_type: 'cloudy', quote_line: '感时花溅泪，恨别鸟惊心。' },
  { title: '登高', poet: '杜甫', dynasty: '唐', content: '风急天高猿啸哀，渚清沙白鸟飞回。无边落木萧萧下，不尽长江滚滚来。', emotion_type: 6, weather_type: 'wind', quote_line: '无边落木萧萧下，不尽长江滚滚来。' },
  { title: '行路难', poet: '李白', dynasty: '唐', content: '金樽清酒斗十千，玉盘珍羞直万钱。停杯投箸不能食，拔剑四顾心茫然。', emotion_type: 5, weather_type: 'cloudy', quote_line: '长风破浪会有时，直挂云帆济沧海。' },
  { title: '如梦令', poet: '李清照', dynasty: '宋', content: '昨夜雨疏风骤，浓睡不消残酒。试问卷帘人，却道海棠依旧。', emotion_type: 3, weather_type: 'rain', quote_line: '知否，知否？应是绿肥红瘦。' },
  { title: '水调歌头', poet: '苏轼', dynasty: '宋', content: '明月几时有？把酒问青天。不知天上宫阙，今夕是何年。', emotion_type: 8, weather_type: 'sunny', quote_line: '但愿人长久，千里共婵娟。' },
  { title: '望岳', poet: '杜甫', dynasty: '唐', content: '岱宗夫如何？齐鲁青未了。造化钟神秀，阴阳割昏晓。', emotion_type: 7, weather_type: 'sunny', quote_line: '会当凌绝顶，一览众山小。' },
  { title: '饮酒', poet: '陶渊明', dynasty: '东晋', content: '结庐在人境，而无车马喧。问君何能尔？心远地自偏。', emotion_type: 2, weather_type: 'sunny', quote_line: '采菊东篱下，悠然见南山。' },
  { title: '虞美人', poet: '李煜', dynasty: '南唐', content: '春花秋月何时了？往事知多少。小楼昨夜又东风，故国不堪回首月明中。', emotion_type: 3, weather_type: 'cloudy', quote_line: '问君能有几多愁？恰似一江春水向东流。' },
  { title: '春夜喜雨', poet: '杜甫', dynasty: '唐', content: '好雨知时节，当春乃发生。随风潜入夜，润物细无声。', emotion_type: 1, weather_type: 'rain', quote_line: '随风潜入夜，润物细无声。' },
  { title: '江雪', poet: '柳宗元', dynasty: '唐', content: '千山鸟飞绝，万径人踪灭。孤舟蓑笠翁，独钓寒江雪。', emotion_type: 2, weather_type: 'snow', quote_line: '孤舟蓑笠翁，独钓寒江雪。' },
  { title: '满江红', poet: '岳飞', dynasty: '宋', content: '怒发冲冠，凭栏处、潇潇雨歇。抬望眼，仰天长啸，壮怀激烈。', emotion_type: 4, weather_type: 'rain', quote_line: '莫等闲、白了少年头，空悲切。' },
  { title: '夜雨寄北', poet: '李商隐', dynasty: '唐', content: '君问归期未有期，巴山夜雨涨秋池。何当共剪西窗烛，却话巴山夜雨时。', emotion_type: 8, weather_type: 'rain', quote_line: '何当共剪西窗烛，却话巴山夜雨时。' },
  { title: '枫桥夜泊', poet: '张继', dynasty: '唐', content: '月落乌啼霜满天，江枫渔火对愁眠。姑苏城外寒山寺，夜半钟声到客船。', emotion_type: 6, weather_type: 'fog', quote_line: '姑苏城外寒山寺，夜半钟声到客船。' },
  { title: '送杜少府', poet: '王勃', dynasty: '唐', content: '城阙辅三秦，风烟望五津。与君离别意，同是宦游人。', emotion_type: 8, weather_type: 'cloudy', quote_line: '海内存知己，天涯若比邻。' },
  { title: '陋室铭', poet: '刘禹锡', dynasty: '唐', content: '山不在高，有仙则名。水不在深，有龙则灵。斯是陋室，惟吾德馨。', emotion_type: 2, weather_type: 'cloudy', quote_line: '斯是陋室，惟吾德馨。' },
  { title: '山居秋暝', poet: '王维', dynasty: '唐', content: '空山新雨后，天气晚来秋。明月松间照，清泉石上流。', emotion_type: 1, weather_type: 'rain', quote_line: '明月松间照，清泉石上流。' },
];

// Auto-seed if poems table is empty
function ensureSeed() {
  const count = db.prepare('SELECT COUNT(*) as cnt FROM poems').get().cnt;
  if (count === 0) {
    const insert = db.prepare('INSERT INTO poems (title, poet, dynasty, content, emotion_type, weather_type, quote_line) VALUES (?,?,?,?,?,?,?)');
    for (const p of seedPoems) {
      insert.run(p.title, p.poet, p.dynasty, p.content, p.emotion_type, p.weather_type, p.quote_line);
    }
  }
}
ensureSeed();

router.get('/match', auth, (req, res) => {
  const { emotion, weather } = req.query;
  let poems = db.prepare('SELECT * FROM poems WHERE emotion_type = ?').all(emotion || 3);
  if (poems.length === 0) poems = db.prepare('SELECT * FROM poems ORDER BY RANDOM() LIMIT 1').all();
  const exactMatch = poems.filter(p => p.weather_type === weather);
  const result = exactMatch.length > 0 ? exactMatch[Math.floor(Math.random() * exactMatch.length)] : poems[Math.floor(Math.random() * poems.length)];
  res.json(result);
});

module.exports = router;
