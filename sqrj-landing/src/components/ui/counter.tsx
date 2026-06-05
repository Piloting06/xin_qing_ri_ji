"use client";

import { useEffect, useRef, useState } from "react";
import { motion, useInView } from "motion/react";

interface CounterProps {
  /** 目标数值 */
  value: number;
  /** 跳动持续时间（ms） */
  duration?: number;
  /** 前缀文字（如 "°C"） */
  prefix?: string;
  /** 后缀文字 */
  suffix?: string;
  className?: string;
}

/**
 * 数字跳动组件。
 * 从 0 跳到目标值，ease-out-quart 缓动。
 */
export function Counter({
  value,
  duration = 2000,
  prefix = "",
  suffix = "",
  className = "",
}: CounterProps) {
  const ref = useRef<HTMLSpanElement>(null);
  const isInView = useInView(ref, { once: true, amount: 0.5 });
  const [display, setDisplay] = useState(0);

  useEffect(() => {
    if (!isInView) return;

    let startTime: number | null = null;
    let raf: number;

    const tick = (timestamp: number) => {
      if (!startTime) startTime = timestamp;
      const elapsed = timestamp - startTime;
      const progress = Math.min(elapsed / duration, 1);

      // ease-out-quart
      const eased = 1 - Math.pow(1 - progress, 4);
      setDisplay(Math.round(eased * value));

      if (progress < 1) {
        raf = requestAnimationFrame(tick);
      }
    };

    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [isInView, value, duration]);

  return (
    <motion.span
      ref={ref}
      className={className}
      initial={{ opacity: 0 }}
      whileInView={{ opacity: 1 }}
      viewport={{ once: true }}
      transition={{ duration: 0.6, ease: [0.25, 1, 0.5, 1] }}
    >
      {prefix}
      {display}
      {suffix}
    </motion.span>
  );
}
