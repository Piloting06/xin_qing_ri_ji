# 心晴日记 — API接口文档

> 版本：v1.0 | 更新：2026-05-12  
> 基础URL: `http://114.55.138.55:8888/api`  
> 除 register/login/health 外均需 Header: `Authorization: Bearer <token>`

## 认证
| 路由 | 方法 | 说明 | 限流 |
|------|------|------|------|
| `/auth/register` | POST | 注册 | 3次/分 |
| `/auth/login` | POST | 登录 | 10次/分 |
| `/auth/change-password` | POST | 改密码 | - |
| `/auth/change-username` | POST | 改用户名 | - |
| `/auth/change-phone` | POST | 改手机号 | - |
| `/auth/delete-account` | POST | 注销 | - |

## 天气
| 路由 | 方法 | 说明 |
|------|------|------|
| `/weather?lat=X&lon=Y` | GET | 3天天气(10min缓存) |
| `/weather/search?q=城市` | GET | 城市搜索(高德API) |
| `/location` | GET | IP定位 |

## 心情
| 路由 | 方法 | 说明 |
|------|------|------|
| `/mood` | POST | 记录/更新心情 |
| `/mood?date=YYYY-MM-DD` | GET | 获取某天心情 |
| `/mood/all` | GET | 所有心情 |
| `/mood/ai-respond` | POST | AI回应(DeepSeek) |

## 日记
| 路由 | 方法 | 说明 |
|------|------|------|
| `/diary` | POST | 创建/更新日记 |
| `/diary?date=YYYY-MM-DD` | GET | 获取某天日记 |
| `/diary/all` | GET | 所有日记 |
| `/diary/search?q=关键词` | GET | 搜索日记 |

## 签到
| 路由 | 方法 | 说明 |
|------|------|------|
| `/checkin` | POST | 签到 |
| `/checkin/status` | GET | 签到状态 |
| `/checkin/card/today` | GET | 今日天气心情卡 |

## 友人
| 路由 | 方法 | 说明 |
|------|------|------|
| `/friends/add` | POST | 加好友(手机号) |
| `/friends/requests` | GET | 好友请求 |
| `/friends/respond` | POST | 同意/拒绝 |
| `/friends/list` | GET | 好友列表 |
| `/friends/:id/mood` | GET | 好友近3天心情 |

## 树洞
| 路由 | 方法 | 说明 |
|------|------|------|
| `/treehole` | GET | 留言列表(分页) |
| `/treehole` | POST | 发留言(每天3条) |
| `/treehole/:id/interact` | POST | 云拥抱/咖啡 |

## 胶囊
| 路由 | 方法 | 说明 |
|------|------|------|
| `/capsule` | POST | 创建 |
| `/capsule/list` | GET | 列表 |
| `/capsule/:id` | GET | 打开 |

## 其他
| 路由 | 方法 | 说明 |
|------|------|------|
| `/poems/match?emotion=X&weather=X` | GET | 古诗匹配 |
| `/wallpapers/unlocked` | GET | 已解锁壁纸 |
| `/wallpapers/check` | GET | 检查新解锁 |
| `/health` | GET | 健康检查 |
