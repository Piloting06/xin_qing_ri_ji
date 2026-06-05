"use client";

import { motion } from "motion/react";
import { useTitleClick } from "@/components/title-click-context";

export function MoodSection() {
  const onTitleClick = useTitleClick();

  return (
    <section
      className="relative flex flex-col items-center overflow-hidden px-6 py-24 md:px-16 md:py-32 lg:px-24"
      style={{ backgroundColor: "#F0D2D2" }}
    >
      <div className="pointer-events-none absolute inset-0 flex flex-col justify-center gap-12 px-8 md:px-20">
        {[0, 1, 2, 3].map((i) => (
          <div key={i} className="relative h-px w-full overflow-hidden">
            <motion.div
              className="absolute inset-0 bg-text-secondary/10"
              initial={{ scaleX: 0 }}
              whileInView={{ scaleX: 1 }}
              viewport={{ once: true, amount: 0.3 }}
              transition={{ duration: 0.8, delay: i * 0.1, ease: [0.25, 1, 0.5, 1] }}
              style={{ originX: 0 }}
            />
          </div>
        ))}
      </div>

      <div className="relative z-10 flex w-full flex-col items-center gap-12 md:flex-row md:items-center md:gap-8 lg:gap-16">
        {/* 左：标题 + 副标题 */}
        <div className="flex-1 text-center md:text-left md:max-w-[40%]">
          <button type="button" onClick={() => onTitleClick?.()} className="font-cn text-2xl font-bold text-text-primary md:text-3xl lg:text-4xl cursor-pointer transition-all hover:text-accent-orange hover:tracking-wide">
            上周三下午四点，特别开心。
          </button>
          <p className="mt-4 max-w-sm text-sm leading-relaxed text-text-secondary md:mt-6 md:text-base mx-auto md:mx-0">
            你的情绪，值得一条完整的曲线。
          </p>
          <div className="flex flex-wrap gap-2 mt-4">
            {["选一个最接近的心情", "写下来就好", "三个月后回看", "原来那天那么开心"].map(tag => (
              <span key={tag} className="px-3 py-1 rounded-full text-xs border" style={{ borderColor: "#C4888830", color: "#C48888" }}>
                {tag}
              </span>
            ))}
          </div>
          <p className="mt-4 text-xs leading-relaxed" style={{ color: "#C48888" }}>
            上周三下午四点，你特别开心。你记下来了。三个月后你才看到。
          </p>
        </div>

        {/* 右：笑脸 + 日期 */}
        <motion.div
          className="flex flex-1 flex-col items-center gap-6 md:max-w-[60%]"
          initial={{ scale: 0 }}
          whileInView={{ scale: 1 }}
          viewport={{ once: true, amount: 0.3 }}
          transition={{ duration: 0.6, delay: 0.3, ease: [0.25, 1, 0.5, 1] }}
        >
          <div className="relative flex h-20 w-20 items-center justify-center rounded-full bg-accent-honey/15 md:h-24 md:w-24">
            <svg
              viewBox="0 0 40 40"
              className="h-10 w-10 md:h-12 md:w-12"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <circle cx="20" cy="20" r="18" className="text-accent-honey" />
              <circle cx="14" cy="16" r="1.5" className="fill-accent-honey" />
              <circle cx="26" cy="16" r="1.5" className="fill-accent-honey" />
              <path d="M13 24 Q20 31 27 24" className="text-accent-honey" />
            </svg>
            <motion.div
              className="absolute inset-0 rounded-full bg-accent-honey/10"
              animate={{ scale: [1, 1.15, 1], opacity: [0.5, 0.8, 0.5] }}
              transition={{ repeat: Infinity, duration: 1.5, ease: "easeInOut" }}
            />
          </div>

          <motion.span
            className="font-en text-xs tracking-[0.2em] text-text-muted"
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true, amount: 0.3 }}
            transition={{ duration: 0.6, delay: 0.5, ease: [0.25, 1, 0.5, 1] }}
          >
            05.28 · WED
          </motion.span>
        </motion.div>
      </div>
    </section>
  );
}
