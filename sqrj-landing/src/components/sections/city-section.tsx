"use client";

import { motion } from "motion/react";
import { useTitleClick } from "@/components/title-click-context";

const CITIES = [
  { x: 8, y: 20, name: "北京" },
  { x: 28, y: 70, name: "上海" },
  { x: 42, y: 45, name: "广州" },
  { x: 60, y: 18, name: "成都" },
  { x: 75, y: 60, name: "杭州" },
  { x: 20, y: 85, name: "武汉" },
  { x: 50, y: 80, name: "西安" },
  { x: 80, y: 35, name: "哈尔滨" },
  { x: 35, y: 10, name: "乌鲁木齐" },
];

export function CitySection() {
  const onTitleClick = useTitleClick();

  return (
    <section
      className="relative flex flex-col overflow-hidden px-6 py-24 md:px-20 md:py-32 lg:px-28"
      style={{ backgroundColor: "#DFD0BC" }}
    >
      {/* 标题在左上角 */}
      <div className="relative z-10 mb-4">
        <button type="button" onClick={() => onTitleClick?.()} className="font-cn text-2xl font-bold text-text-primary md:text-3xl lg:text-4xl cursor-pointer transition-all hover:text-accent-orange hover:tracking-wide">
          咦，你也在啊。
        </button>
        <div className="flex flex-wrap gap-2 mt-4">
          {["你不是一个人", "没有人知道你是谁", "每座城市都有人在说话", "凌晨一点也有人醒着"].map(tag => (
            <span key={tag} className="px-3 py-1 rounded-full text-xs border" style={{ borderColor: "#A8907030", color: "#A89070" }}>
              {tag}
            </span>
          ))}
        </div>
        <p className="mt-4 text-xs leading-relaxed" style={{ color: "#A89070" }}>
          凌晨一点，你看到成都有人说「今天终于放晴了」。你也笑了。
        </p>
      </div>

      {/* 光点散落整个区域 */}
      <div className="relative z-10 flex-1">
        {CITIES.map((city, i) => (
          <motion.div
            key={city.name}
            className="absolute"
            initial={{ opacity: 0, scale: 0 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true, amount: 0.3 }}
            transition={{ duration: 0.5, delay: i * 0.08, ease: [0.25, 1, 0.5, 1] }}
            style={{
              left: `${city.x}%`,
              top: `${city.y}%`,
            }}
          >
            <div className="relative">
              <div className="h-2 w-2 rounded-full bg-accent-honey" />
              <motion.div
                className="absolute -inset-1.5 rounded-full bg-accent-honey/15"
                animate={{ scale: [1, 2, 1], opacity: [0.4, 0, 0.4] }}
                transition={{ repeat: Infinity, duration: 2, delay: i * 0.3 }}
              />
              <span className="absolute -top-5 left-1/2 -translate-x-1/2 whitespace-nowrap text-[11px] text-text-muted md:text-xs">
                {city.name}
              </span>
            </div>
          </motion.div>
        ))}

        {/* 还有更多提示 */}
        <motion.p
          className="absolute bottom-4 right-4 font-en text-[10px] tracking-widest text-text-muted/50"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true, amount: 0.3 }}
          transition={{ duration: 0.5, delay: CITIES.length * 0.08 + 0.1, ease: [0.25, 1, 0.5, 1] }}
        >
          + 50 MORE
        </motion.p>
      </div>

      {/* 留言气泡浮在右下区域 */}
      <motion.div
        className="absolute right-16 bottom-48 z-10 rounded-xl border border-accent-honey/15 bg-bg-card/80 px-4 py-3 shadow-lg backdrop-blur-sm md:right-24 md:bottom-64 md:px-5 md:py-4"
        initial={{ opacity: 0, y: 16 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, amount: 0.3 }}
        transition={{ duration: 0.6, delay: 0.5, ease: [0.25, 1, 0.5, 1] }}
      >
        <p className="text-sm text-text-secondary md:text-base">
          <span className="text-accent-honey/60">&quot;</span>
          今天终于放晴了
          <span className="text-accent-honey/60">&quot;</span>
        </p>
        <span className="mt-1 block text-[10px] text-text-muted">— 北京</span>
      </motion.div>
    </section>
  );
}
