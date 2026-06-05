"use client";

import { motion, useTransform } from "motion/react";
import { useSectionScroll } from "@/components/use-section-scroll";
import { type ReactNode } from "react";

interface ParallaxLayerProps {
  children: ReactNode;
  /** 滚动速度倍率：0 = 不动，1 = 正常，>1 = 比正常快 */
  speed?: number;
  className?: string;
}

/**
 * 视差层组件。
 * 根据滚动位置偏移元素，实现视差效果。
 */
export function ParallaxLayer({
  children,
  speed = 0.3,
  className = "",
}: ParallaxLayerProps) {
  const { scrollYProgress } = useSectionScroll();
  const y = useTransform(scrollYProgress, [0, 1], [0, -100 * speed]);

  return (
    <motion.div className={className} style={{ y }}>
      {children}
    </motion.div>
  );
}
