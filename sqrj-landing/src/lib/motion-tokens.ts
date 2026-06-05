/**
 * 动效 Token — 拾晴日记
 *
 * 统一时长、缓动、弹簧、位移参数。
 * 所有动效都从这里取值，不硬编码。
 */

export const duration = {
  fast: 150,     // 微交互（hover、press）
  normal: 300,   // 元素进入/退出
  slow: 600,     // 全屏过渡
  crawl: 1200,   // 背景缓慢变化
} as const;

/** ease-out-quart — 元素进入 */
export const easingEnter = [0.25, 1, 0.5, 1] as const;

/** ease-in-quart — 元素退出 */
export const easingExit = [0.5, 0, 0.75, 0] as const;

/** 通用平滑 */
export const easingSmooth = [0.25, 0.1, 0.25, 1] as const;

export const spring = {
  gentle: { stiffness: 120, damping: 20, mass: 1 },
  snappy: { stiffness: 300, damping: 30, mass: 1 },
} as const;

export const distance = {
  sm: 20,   // 小位移
  md: 40,   // 中位移
  lg: 80,   // 大位移
} as const;

/** 呼吸式淡入参数 */
export const breathe = {
  /** WEATHER → REMEMBERS 的关键停顿（ms） */
  pauseBeforeRemembers: 500,
  /** 每字淡入持续时间（ms） */
  wordFadeDuration: 600,
  /** 字间距（px） */
  letterSpacing: 8,
} as const;

/** 视差层级滚动速度倍率 */
export const parallaxSpeed = {
  layer0: 0.1,  // 最远：背景渐变/粒子
  layer1: 0.3,  // 装饰图形/光晕
  layer2: 1,    // 主内容
  layer3: 1.2,  // 最近：前景浮动元素
} as const;
