"use client";

import { motion } from "motion/react";

type AnchorColor = "honey" | "mint" | "blush" | "muted";

const colorMap: Record<AnchorColor, { ring: string; text: string }> = {
  honey: { ring: "border-accent-honey", text: "text-accent-honey" },
  mint: { ring: "border-accent-mint", text: "text-accent-mint" },
  blush: { ring: "border-accent-blush", text: "text-accent-blush" },
  muted: { ring: "border-text-secondary/30", text: "text-text-secondary/50" },
};

interface SectionAnchorProps {
  color?: AnchorColor;
  onClick?: () => void;
}

/**
 * "了解更多" 呼吸光圈 — 右下角可见但克制的交互提示。
 * 一个暖色圆环缓慢呼吸，hover 时浮出"了解更多"。
 */
export function SectionAnchor({ color = "honey", onClick }: SectionAnchorProps) {
  const c = colorMap[color];

  return (
    <motion.button
      onClick={onClick}
      aria-label="了解更多"
      className="group absolute bottom-12 right-8 z-10 flex h-14 w-14 cursor-pointer items-center justify-center md:bottom-16 md:right-12"
    >
      {/* 呼吸光圈 */}
      <motion.span
        className={`absolute inset-0 rounded-full border ${c.ring} opacity-40`}
        animate={{
          scale: [1, 1.15, 1],
          opacity: [0.3, 0.6, 0.3],
        }}
        transition={{ repeat: Infinity, duration: 1.8, ease: "easeInOut" }}
      />
      <motion.span
        className={`absolute inset-0 rounded-full border ${c.ring} opacity-20`}
        animate={{
          scale: [1, 1.3, 1],
          opacity: [0.15, 0.35, 0.15],
        }}
        transition={{
          repeat: Infinity,
          duration: 1.8,
          ease: "easeInOut",
          delay: 0.6,
        }}
      />

      {/* 中心小点 — 使用 bg- 填充 */}
      <motion.span
        className={`relative z-10 h-1.5 w-1.5 rounded-full ${
          color === "muted" ? "bg-text-secondary/50" : c.ring.replace("border-", "bg-")
        }`}
        animate={{ opacity: [0.5, 1, 0.5] }}
        transition={{ repeat: Infinity, duration: 1.8, ease: "easeInOut" }}
      />

      {/* hover 时浮现文字 */}
      <motion.span
        className={`absolute -bottom-7 left-1/2 -translate-x-1/2 whitespace-nowrap text-[11px] tracking-widest ${c.text} pointer-events-none opacity-0 group-hover:opacity-100 transition-opacity duration-300`}
      >
        了解更多
      </motion.span>
    </motion.button>
  );
}
