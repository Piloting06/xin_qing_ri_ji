# 拾晴日记

一款将天气与心情融合的日记应用。记录每一天的情感，生成精美卡片，与朋友分享你的晴雨。

## 功能

- **天气日记** — 自动获取当前天气，将天气与心情绑定记录
- **心情卡片** — 8 种情绪，自动生成可分享的心情卡片，支持温润/方寸两种风格
- **时光胶囊** — 给未来的自己写一封信，到期自动提醒开启
- **城迹地图** — 记录你到过的城市，生成专属足迹
- **好友圈** — 添加好友，查看彼此的心情动态
- **心情曲线** — 可视化你的情绪变化趋势
- **隐私优先** — 数据存储在自有服务器，不接入第三方分析

## 技术栈

| 层 | 技术 |
|---|------|
| 前端 | Flutter 3.x / Dart |
| 状态管理 | Provider |
| 后端 | Node.js / Express |
| 数据库 | SQLite |
| 推送 | flutter_local_notifications |
| 定位 | geolocator + 高德 Web API |
| 邮件 | Resend API |

## 项目结构

```
lib/
  api/          # API 客户端
  constants/    # 常量与 Key
  pages/        # 页面（天气、心情、城迹、我的、胶囊、好友…）
  services/     # 通知、定位等服务
  stores/       # Provider 状态管理
  utils/        # 工具函数
  widgets/      # 通用组件（卡片制作器、导航栏…）
```

## 开始

```bash
# 安装依赖
flutter pub get

# 运行调试
flutter run

# 构建 APK
flutter build apk --release --target-platform android-arm64
```

## 环境变量

在项目根目录创建 `.env`：

```
GAODE_API_KEY=你的高德Key
```

## 许可

本项目为个人作品，暂不开源许可。
