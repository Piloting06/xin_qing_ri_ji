"use client";

import { useRef } from "react";
import { motion, useTransform, type MotionValue } from "motion/react";
import { type ReactNode } from "react";
import { useSectionScroll } from "@/components/use-section-scroll";

interface ScrollRevealProps {
  children: ReactNode;
  className?: string;
  y?: [number, number];
  opacity?: [number, number];
  scale?: [number, number];
  x?: [number, number];
  scrollProgress?: MotionValue<number>;
}

export function ScrollReveal({
  children,
  className = "",
  y = [60, 0],
  opacity = [0, 1],
  scale = [1, 1],
  x = [0, 0],
  scrollProgress,
}: ScrollRevealProps) {
  const ref = useRef<HTMLDivElement>(null);

  const { scrollYProgress } = useSectionScroll({
    target: ref,
    offset: ["start end", "end start"],
  });

  const progress = scrollProgress ?? scrollYProgress;

  const translateY = useTransform(progress, [0, 1], y);
  const opacityVal = useTransform(
    progress,
    [0, 0.3, 0.7, 1],
    [opacity[0], opacity[1], opacity[1], opacity[0]]
  );
  const scaleVal = useTransform(
    progress,
    [0, 0.4, 0.6, 1],
    [scale[0], scale[1], scale[1], scale[0]]
  );
  const translateX = useTransform(progress, [0, 1], x);

  return (
    <motion.div
      ref={ref}
      className={className}
      style={{
        y: translateY,
        x: translateX,
        opacity: opacityVal,
        scale: scaleVal,
      }}
    >
      {children}
    </motion.div>
  );
}

/**
 * 视差层 — 根据滚动速度倍率偏移。
 * 用于 background 和 foreground 营造深度。
 */
export function ParallaxLayer({
  children,
  className = "",
  speed = 0.5,
}: {
  children: ReactNode;
  className?: string;
  speed?: number;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useSectionScroll({
    target: ref,
    offset: ["start end", "end start"],
  });

  const y = useTransform(scrollYProgress, [0, 1], [100 * speed, -100 * speed]);

  return (
    <motion.div ref={ref} className={`pointer-events-none ${className}`} style={{ y }}>
      {children}
    </motion.div>
  );
}

/**
 * 全局视差 — 贯穿整个页面的背景粒子层。
 */
export function GlobalParallax() {
  const { scrollYProgress } = useSectionScroll();

  const y1 = useTransform(scrollYProgress, [0, 1], [0, -300]);
  const y2 = useTransform(scrollYProgress, [0, 1], [0, -150]);
  const y3 = useTransform(scrollYProgress, [0, 1], [0, -500]);

  return (
    <div className="pointer-events-none fixed inset-0 z-0 overflow-hidden">
      {/* 大型光斑 — 极慢，低透明度 */}
      <motion.div
        className="absolute -top-40 -left-20 h-[600px] w-[600px] rounded-full opacity-[0.04]"
        style={{
          y: y3,
          background: "radial-gradient(circle, rgba(240,178,122,0.8) 0%, transparent 70%)",
        }}
      />
      <motion.div
        className="absolute top-[40%] -right-32 h-[500px] w-[500px] rounded-full opacity-[0.03]"
        style={{
          y: y1,
          background: "radial-gradient(circle, rgba(126,200,192,0.6) 0%, transparent 70%)",
        }}
      />
      <motion.div
        className="absolute top-[70%] left-[20%] h-[400px] w-[400px] rounded-full opacity-[0.025]"
        style={{
          y: y2,
          background: "radial-gradient(circle, rgba(212,160,160,0.6) 0%, transparent 70%)",
        }}
      />
    </div>
  );
}
