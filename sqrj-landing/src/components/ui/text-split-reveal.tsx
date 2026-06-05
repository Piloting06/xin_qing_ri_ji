"use client";

import { motion } from "motion/react";

interface TextSplitRevealProps {
  text: string;
  className?: string;
  /** 每个字符的动画延迟（秒） */
  stagger?: number;
  /** 从中心向两边散开，还是从左到右 */
  from?: "left" | "center";
}

export function TextSplitReveal({
  text,
  className = "",
  stagger = 0.04,
  from = "left",
}: TextSplitRevealProps) {
  const chars = text.split("");

  const getDelay = (index: number) => {
    if (from === "center") {
      const center = (chars.length - 1) / 2;
      const distance = Math.abs(index - center);
      return distance * stagger;
    }
    return index * stagger;
  };

  return (
    <span className={className} aria-label={text}>
      {chars.map((char, i) => (
        <motion.span
          key={i}
          className="inline-block"
          initial={{ opacity: 0, y: 16, filter: "blur(4px)" }}
          whileInView={{ opacity: 1, y: 0, filter: "blur(0px)" }}
          viewport={{ once: true }}
          transition={{
            duration: 0.5,
            delay: getDelay(i),
            ease: [0.25, 1, 0.5, 1],
          }}
        >
          {char === " " ? " " : char}
        </motion.span>
      ))}
    </span>
  );
}
