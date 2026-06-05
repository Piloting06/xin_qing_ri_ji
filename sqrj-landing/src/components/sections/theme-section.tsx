"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { useTitleClick } from "@/components/title-click-context";

const THEMES = [
  { name: "晴日暖白", bg: "#FFF8F0", accent: "#F0B27A", surface: "#FFF0E0" },
  { name: "静夜深蓝", bg: "#0A1120", accent: "#7EC8C0", surface: "#111D33" },
  { name: "雾感薄荷", bg: "#EAF5F3", accent: "#7EC8C0", surface: "#D4EDE9" },
  { name: "豆沙柔粉", bg: "#F8F0F0", accent: "#D4A0A0", surface: "#F0E0E0" },
];

export function ThemeSection() {
  const onTitleClick = useTitleClick();
  const [activeIndex, setActiveIndex] = useState(0);
  const active = THEMES[activeIndex];

  return (
    <section
      className="relative flex flex-col items-start overflow-hidden px-6 py-24 md:px-16 md:py-32 lg:px-24"
      style={{ backgroundColor: "#E5CDB5" }}
    >
      <div className="relative z-10 flex w-full flex-col gap-12">
        <div className="text-center md:text-left">
          <button type="button" onClick={() => onTitleClick?.()} className="font-cn text-2xl font-bold text-text-primary md:text-3xl lg:text-4xl cursor-pointer transition-all hover:text-accent-orange hover:tracking-wide">
            长这样。还能长这样。
          </button>
          <p className="mt-4 max-w-sm text-sm leading-relaxed text-text-secondary md:mt-5 md:text-base mx-auto md:mx-0">
            四套主题，跟着你的感觉走。
          </p>
          <div className="flex flex-wrap gap-2 mt-4">
            {["像清晨的光", "像深夜的安静", "像雨后的空气", "像傍晚的温柔"].map(tag => (
              <span key={tag} className="px-3 py-1 rounded-full text-xs border" style={{ borderColor: "#D0906030", color: "#D09060" }}>
                {tag}
              </span>
            ))}
          </div>
          <p className="mt-4 text-xs leading-relaxed" style={{ color: "#D09060" }}>
            深夜了，你切换到深蓝主题。屏幕暗下来，但你还在写。
          </p>
        </div>

        {/* 纯 CSS 主题色块 — 不用截图 */}
        <motion.div
          className="relative"
          initial={{ scale: 0.96, opacity: 0 }}
          whileInView={{ scale: 1, opacity: 1 }}
          viewport={{ once: true, amount: 0.3 }}
          transition={{ duration: 0.6, ease: [0.25, 1, 0.5, 1] }}
        >
          <div className="relative h-56 w-48 overflow-hidden rounded-2xl shadow-xl md:h-72 md:w-56">
            <AnimatePresence mode="wait">
              <motion.div
                key={activeIndex}
                className="absolute inset-0 flex flex-col gap-3 p-5"
                style={{ backgroundColor: active.bg }}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.4, ease: [0.25, 1, 0.5, 1] }}
              >
                {/* 模拟状态栏 */}
                <div className="flex items-center justify-between">
                  <motion.div
                    className="h-2 w-10 rounded"
                    style={{ backgroundColor: active.accent + "40" }}
                  />
                  <div className="flex gap-1">
                    <motion.div
                      className="h-1.5 w-1.5 rounded-full"
                      style={{ backgroundColor: active.accent }}
                    />
                    <motion.div
                      className="h-1.5 w-1.5 rounded-full"
                      style={{ backgroundColor: active.accent + "30" }}
                    />
                  </div>
                </div>
                {/* 中间内容区 */}
                <motion.div
                  className="mx-auto mt-2 flex w-full max-w-[140px] flex-1 flex-col gap-2 rounded-xl p-4"
                  style={{ backgroundColor: active.surface }}
                >
                  <motion.div
                    className="h-2 w-14 rounded"
                    style={{ backgroundColor: active.accent + "60" }}
                  />
                  <motion.div
                    className="h-1.5 w-20 rounded"
                    style={{ backgroundColor: active.accent + "35" }}
                  />
                  <motion.div
                    className="h-1.5 w-16 rounded"
                    style={{ backgroundColor: active.accent + "25" }}
                  />
                  <motion.div
                    className="mt-2 h-1 w-10 rounded"
                    style={{ backgroundColor: active.accent + "20" }}
                  />
                </motion.div>
                {/* 模拟底部 */}
                <div className="flex justify-around">
                  {[0, 1, 2, 3].map((i) => (
                    <motion.div
                      key={i}
                      className="h-1 w-5 rounded"
                      style={{
                        backgroundColor:
                          i === 0 ? active.accent : active.accent + "25",
                      }}
                    />
                  ))}
                </div>
              </motion.div>
            </AnimatePresence>
          </div>

          {/* 背后的颜色光晕 */}
          <motion.div
            className="pointer-events-none absolute -inset-10 -z-10 rounded-3xl opacity-20 blur-2xl"
            style={{ backgroundColor: active.accent }}
            animate={{ opacity: [0.1, 0.25, 0.1] }}
            transition={{ repeat: Infinity, duration: 1.8, ease: "easeInOut" }}
          />
        </motion.div>

        {/* 色标圆点 */}
        <motion.div
          className="flex items-center gap-4"
          initial={{ opacity: 0, y: 10 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, amount: 0.3 }}
          transition={{ duration: 0.5, delay: 0.2, ease: [0.25, 1, 0.5, 1] }}
        >
          {THEMES.map((theme, i) => (
            <motion.button
              key={theme.name}
              className="relative flex h-11 w-11 items-center justify-center rounded-full"
              onClick={() => setActiveIndex(i)}
              aria-label={theme.name}
              whileHover={{ scale: 1.2 }}
              whileTap={{ scale: 0.9 }}
            >
              <span
                className="h-5 w-5 rounded-full border-2 transition-colors duration-300"
                style={{
                  backgroundColor: theme.bg,
                  borderColor: i === activeIndex ? theme.accent : "transparent",
                }}
              />
              {i === activeIndex && (
                <motion.div
                  className="absolute inset-0 rounded-full"
                  style={{ boxShadow: `0 0 8px ${theme.accent}60` }}
                  layoutId="theme-glow"
                  transition={{ duration: 0.3 }}
                />
              )}
            </motion.button>
          ))}
        </motion.div>
      </div>
    </section>
  );
}
