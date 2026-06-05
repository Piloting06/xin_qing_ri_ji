"use client";

import { motion } from "motion/react";
import { type ReactNode } from "react";

interface TextRevealProps {
  children: ReactNode;
  /** 延迟开始时间（秒） */
  delay?: number;
  /** 每个字的淡入时长（ms） */
  wordDuration?: number;
  /** 字间延迟（ms） */
  wordDelay?: number;
  className?: string;
}

/**
 * 文字逐字淡入组件。
 * 接收纯文字 children，逐字拆分并 stagger 淡入。
 */
export function TextReveal({
  children,
  delay = 0,
  wordDuration = 600,
  wordDelay = 80,
  className = "",
}: TextRevealProps) {
  const text = typeof children === "string" ? children : "";
  if (!text) return null;

  const words = text.split(/(\s+)/); // 保留空格

  return (
    <motion.span
      className={className}
      initial="hidden"
      whileInView="visible"
      viewport={{ once: true, amount: 0.5 }}
    >
      {words.map((word, i) => (
        <motion.span
          key={i}
          className="inline-block"
          variants={{
            hidden: { opacity: 0, y: 12, filter: "blur(4px)" },
            visible: {
              opacity: 1,
              y: 0,
              filter: "blur(0px)",
              transition: {
                duration: wordDuration / 1000,
                delay: delay + (i * wordDelay) / 1000,
                ease: [0.25, 1, 0.5, 1],
              },
            },
          }}
        >
          {word === " " ? " " : word}
        </motion.span>
      ))}
    </motion.span>
  );
}
