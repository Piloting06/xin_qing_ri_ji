"use client";

import { motion } from "motion/react";

export function HeroSection() {
  return (
    <section className="relative flex flex-col items-center justify-center overflow-hidden px-6 py-24 md:px-16 md:py-32 lg:px-24">
      {/* CSS 光点层 */}
      <div className="pointer-events-none absolute inset-0">
        <CSSParticles />
      </div>

      {/* 中文标题 */}
      <div className="relative z-10 flex flex-col items-center gap-6 px-0">
        {/* 副标题 — 细字，宽字距 */}
        <motion.p
          className="font-body text-sm font-light tracking-[0.2em] text-text-secondary md:text-base lg:text-lg"
          initial={{ opacity: 0, y: 8 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, ease: [0.25, 1, 0.5, 1] }}
        >
          天气加心情
        </motion.p>

        {/* 主标题 — 粗体大字 */}
        <motion.h1
          className="font-cn text-4xl font-bold text-text-primary md:text-6xl lg:text-7xl"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.7, delay: 0.2, ease: [0.25, 1, 0.5, 1] }}
        >
          天气会记得你。
        </motion.h1>

        {/* 描述文字 */}
        <motion.p
          className="max-w-md text-center text-base leading-relaxed text-text-secondary md:text-lg"
          initial={{ opacity: 0, y: 12 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.4, ease: [0.25, 1, 0.5, 1] }}
        >
          每一天的天气和心情，都值得被记住。
          <br />
          写下来，发给 Ta。
        </motion.p>
      </div>

      {/* 向下箭头 */}
      <motion.div
        className="relative z-10 mt-12"
        initial={{ opacity: 0 }}
        whileInView={{ opacity: 1 }}
        viewport={{ once: true }}
        transition={{ delay: 0.8, duration: 0.8 }}
      >
        <motion.span
          className="block text-xl text-text-muted"
          animate={{ y: [0, 6, 0] }}
          transition={{ repeat: Infinity, duration: 1.5, ease: "easeInOut" }}
        >
          ↓
        </motion.span>
      </motion.div>
    </section>
  );
}

function CSSParticles() {
  const particles = Array.from({ length: 8 });

  return (
    <>
      {particles.map((_, i) => (
        <motion.div
          key={i}
          className="absolute rounded-full"
          style={{
            width: 40 + i * 8,
            height: 40 + i * 8,
            left: `${10 + i * 10}%`,
            top: `${30 + i * 6}%`,
            background: `radial-gradient(circle, ${
              i % 3 === 0
                ? "rgba(240,178,122,0.08)"
                : i % 3 === 1
                  ? "rgba(126,200,192,0.06)"
                  : "rgba(212,160,160,0.05)"
            } 0%, transparent 60%)`,
            filter: "blur(8px)",
          }}
          animate={{
            y: [0, -25 - i * 5, 0],
            x: [0, i % 2 === 0 ? 12 : -12, 0],
            opacity: [0.3, 0.5, 0.3],
          }}
          transition={{
            repeat: Infinity,
            duration: 5 + i * 1.5,
            delay: i * 0.7,
            ease: "easeInOut",
          }}
        />
      ))}
    </>
  );
}
