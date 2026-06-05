"use client";

import { motion } from "motion/react";
import { useTitleClick } from "@/components/title-click-context";

export function CardSection() {
  const onTitleClick = useTitleClick();

  return (
    <section
      className="relative flex flex-col items-start overflow-hidden px-6 py-24 md:px-16 md:py-32 lg:px-24"
      style={{ backgroundColor: "#EDD5B5" }}
    >
      <div className="relative z-10 flex w-full flex-col gap-12 md:flex-row md:items-center">
        {/* 左：标题 + 文字描述 */}
        <div className="flex-1 text-center md:text-left">
          <button type="button" onClick={() => onTitleClick?.()} className="font-cn text-2xl font-bold text-text-primary md:text-3xl lg:text-4xl cursor-pointer transition-all hover:text-accent-orange hover:tracking-wide">
            发给Ta。
          </button>
          <p className="mt-4 max-w-sm text-sm leading-relaxed text-text-secondary md:mt-6 md:text-base mx-auto md:mx-0">
            文字日记是私人的。但有些心情，想让 Ta 看到。
          </p>
          <div className="flex flex-wrap gap-2 mt-4">
            {["暖白 · 深蓝 · 薄荷 · 柔粉", "圆的方的都行", "发给 Ta 不用多说", "存进相册留着"].map(tag => (
              <span key={tag} className="px-3 py-1 rounded-full text-xs border" style={{ borderColor: "#D4A06030", color: "#D4A060" }}>
                {tag}
              </span>
            ))}
          </div>
          <p className="mt-4 text-xs leading-relaxed" style={{ color: "#D4A060" }}>
            你把今天的心情做成一张卡片，发给了 Ta。Ta 没有回复，但你看到已读。
          </p>
        </div>

        {/* 右：卡片视觉 — 右侧偏移 */}
        <div className="relative flex h-72 w-full items-center justify-center md:h-80 md:w-auto md:flex-shrink-0">
          <motion.div
            className="relative z-10 flex h-56 w-80 flex-col justify-between rounded-2xl border border-accent-honey/20 bg-bg-card p-6 shadow-lg shadow-accent-honey/5 md:h-64 md:w-96"
            initial={{ scale: 0.8, x: -100, rotateY: 15 }}
            whileInView={{ scale: 1, x: 0, rotateY: 0 }}
            viewport={{ once: true, amount: 0.3 }}
            transition={{ type: "spring", stiffness: 100, damping: 18 }}
            style={{ willChange: "transform" }}
          >
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <motion.div
                  className="h-5 w-5 rounded-full bg-accent-honey/30"
                  animate={{ scale: [1, 1.2, 1] }}
                  transition={{ repeat: Infinity, duration: 1.2 }}
                />
                <span className="text-xs text-text-muted">2026.05.28</span>
              </div>
              <div className="h-1.5 w-3/4 rounded bg-text-secondary/10" />
              <div className="h-1.5 w-1/2 rounded bg-text-secondary/10" />
            </div>
            <div className="flex items-center justify-between">
              <div className="flex gap-1.5">
                <div className="h-2 w-2 rounded-full bg-accent-honey" />
                <div className="h-2 w-2 rounded-full bg-accent-mint/50" />
                <div className="h-2 w-2 rounded-full bg-accent-blush/50" />
              </div>
              <span className="font-en text-xs text-text-muted">SQRJ</span>
            </div>
          </motion.div>

          {/* 线条手型 — 更大更明显 */}
          <motion.svg
            className="absolute z-20 h-20 w-20 md:h-24 md:w-24"
            viewBox="0 0 60 60"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            initial={{ opacity: 0, x: -50 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, amount: 0.3 }}
            transition={{ duration: 0.6, delay: 0.4, ease: [0.25, 1, 0.5, 1] }}
            style={{
              left: "calc(50% + 70px)",
              top: "calc(50% - 30px)",
            }}
          >
            <path
              d="M30 50 L30 28 L24 22 L24 30 L18 24 L18 32 L12 28 L12 36 Q12 42 20 44 L28 44 L36 44 Q42 44 42 38 L42 24 L36 18 L36 30 L30 24 L30 30"
              className="text-text-secondary/50"
            />
          </motion.svg>

          <motion.span
            className="absolute z-30 text-sm tracking-wider text-accent-honey/80 md:text-base"
            initial={{ opacity: 0, x: -24 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, amount: 0.3 }}
            transition={{ duration: 0.6, delay: 0.6, ease: [0.25, 1, 0.5, 1] }}
            style={{
              right: "8%",
              top: "calc(50% - 10px)",
            }}
          >
            发给Ta。
          </motion.span>
        </div>
      </div>
    </section>
  );
}
