"use client";

import { motion, useTransform } from "motion/react";
import { useSectionScroll } from "@/components/use-section-scroll";

export function AtmosphereLayer() {
  const { scrollYProgress } = useSectionScroll();

  const y1 = useTransform(scrollYProgress, [0, 1], [0, -400]);
  const y2 = useTransform(scrollYProgress, [0, 1], [0, -250]);
  const y3 = useTransform(scrollYProgress, [0, 1], [0, -600]);
  const rotate1 = useTransform(scrollYProgress, [0, 1], [0, 30]);
  const rotate2 = useTransform(scrollYProgress, [0, 1], [0, -20]);

  return (
    <div className="pointer-events-none fixed inset-0 z-0 overflow-hidden">
      {/* 大型暖光斑 — 极慢 */}
      <motion.div
        className="absolute -top-60 -left-40 h-[700px] w-[700px] rounded-full opacity-[0.07]"
        style={{
          y: y3,
          rotate: rotate1,
          background: "radial-gradient(circle, rgba(240,178,122,0.9) 0%, transparent 70%)",
        }}
      />
      {/* 中型玫瑰光斑 */}
      <motion.div
        className="absolute top-[35%] -right-48 h-[500px] w-[500px] rounded-full opacity-[0.06]"
        style={{
          y: y1,
          rotate: rotate2,
          background: "radial-gradient(circle, rgba(212,160,160,0.8) 0%, transparent 70%)",
        }}
      />
      {/* 小型蜂蜜光斑 */}
      <motion.div
        className="absolute top-[65%] left-[15%] h-[400px] w-[400px] rounded-full opacity-[0.05]"
        style={{
          y: y2,
          background: "radial-gradient(circle, rgba(232,152,110,0.7) 0%, transparent 70%)",
        }}
      />
    </div>
  );
}
