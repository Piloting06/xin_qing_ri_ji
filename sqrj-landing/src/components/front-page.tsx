"use client";

import { motion } from "motion/react";
import Image from "next/image";

export function FrontPage() {
  return (
    <section
      className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden"
      style={{
        background:
          "radial-gradient(ellipse 60% 60% at 50% 40%, #F5C89A 0%, #F0B27A 50%, #E8A56C 100%)",
      }}
    >
      <div
        className="pointer-events-none absolute inset-0"
        style={{
          background:
            "radial-gradient(circle at 50% 50%, rgba(255,255,255,0.15) 0%, transparent 60%)",
        }}
      />

      <div className="relative z-10 flex flex-col items-center gap-8 px-4">
        {/* Icon */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, ease: [0.25, 1, 0.5, 1] }}
        >
          <Image
            src="/screenshots/app-icon.png"
            alt="拾晴日记"
            width={80}
            height={80}
            className="rounded-2xl shadow-lg"
          />
        </motion.div>

        {/* Name — handwritten */}
        <motion.h1
          className="font-cn text-5xl text-white md:text-6xl lg:text-7xl"
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.15, ease: [0.25, 1, 0.5, 1] }}
        >
          拾晴日记
        </motion.h1>

        {/* Slogan */}
        <motion.p
          className="text-lg text-white/80 md:text-xl"
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.25, ease: [0.25, 1, 0.5, 1] }}
        >
          天气加心情。写下来，发给Ta。
        </motion.p>

        {/* Download button — QQ style */}
        <motion.a
          href="/sqrj.apk"
          download
          className="flex h-14 items-center justify-center rounded-full bg-white px-12 text-lg font-semibold text-accent-orange shadow-lg shadow-accent-orange/30 transition-all hover:scale-[1.03] hover:shadow-xl active:scale-[0.98] md:h-16 md:px-16 md:text-xl"
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.35, ease: [0.25, 1, 0.5, 1] }}
        >
          立即下载
        </motion.a>

        {/* Version info */}
        <motion.p
          className="text-sm text-white/50"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.6, delay: 0.45 }}
        >
          Android 7.0+
        </motion.p>

        {/* Down arrow */}
        <motion.div
          className="absolute bottom-12"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.6, duration: 0.8 }}
        >
          <motion.span
            className="block text-2xl text-white/60"
            animate={{ y: [0, 8, 0] }}
            transition={{ repeat: Infinity, duration: 1.5, ease: "easeInOut" }}
          >
            ↓
          </motion.span>
        </motion.div>
      </div>
    </section>
  );
}
