"use client";

import { motion } from "motion/react";
import { Counter } from "@/components/ui/counter";
import { useTitleClick } from "@/components/title-click-context";
import { TextSplitReveal } from "@/components/ui/text-split-reveal";

export function WeatherSection() {
  const onTitleClick = useTitleClick();

  return (
    <section
      className="relative flex flex-col justify-center overflow-hidden px-6 py-24 md:px-20 md:py-32 lg:px-32"
      style={{ backgroundColor: "#EDD5BF" }}
    >
      {/* 云层视差 — 浅色背景用更淡的云 */}
      <motion.div
        className="pointer-events-none absolute inset-0"
        animate={{ y: [0, -20, 0] }}
        transition={{ repeat: Infinity, duration: 6, ease: "easeInOut" }}
      >
        <div className="absolute left-[5%] top-[25%] h-32 w-64 rounded-full bg-text-secondary/5 blur-3xl" />
      </motion.div>
      <motion.div
        className="pointer-events-none absolute inset-0"
        animate={{ y: [0, -20, 0] }}
        transition={{ repeat: Infinity, duration: 6, delay: 1.5, ease: "easeInOut" }}
      >
        <div className="absolute right-[10%] top-[50%] h-40 w-72 rounded-full bg-accent-mint/5 blur-3xl" />
      </motion.div>
      <motion.div
        className="pointer-events-none absolute inset-0"
        animate={{ y: [0, -20, 0] }}
        transition={{ repeat: Infinity, duration: 6, delay: 3, ease: "easeInOut" }}
      >
        <div className="absolute left-[30%] top-[70%] h-28 w-56 rounded-full bg-accent-honey/5 blur-3xl" />
      </motion.div>

      {/* 标题 — 逐字手写浮现 */}
      <div className="relative z-10 mb-8 text-center md:mb-12">
        <button type="button" onClick={() => onTitleClick?.()} className="font-cn text-2xl font-bold text-text-primary md:text-3xl lg:text-4xl cursor-pointer transition-all hover:text-accent-orange hover:tracking-wide">
          <TextSplitReveal text="又下雨了。" from="center" stagger={0.06} />
        </button>
      </div>

      {/* 主体 — 左右分家 */}
      <div className="relative z-10 flex flex-col-reverse items-center justify-between gap-8 md:flex-row md:items-end md:gap-0">
        {/* 左：文案 */}
        <div className="flex-1 text-center md:text-left">
          <p className="max-w-[240px] text-sm leading-relaxed text-text-secondary md:text-base lg:text-lg">
            你不看消息。
            <br />
            你先看外面。
          </p>
          <div className="flex flex-wrap gap-2 mt-4">
            {["打开就知道你在哪", "没信号也能看", "明天要不要带伞", "今天适合出门吗"].map(tag => (
              <span key={tag} className="px-3 py-1 rounded-full text-xs border" style={{ borderColor: "#C4906030", color: "#C49060" }}>
                {tag}
              </span>
            ))}
          </div>
          <p className="mt-4 text-xs leading-relaxed" style={{ color: "#C49060" }}>
            周五下午三点，广州，26°C。你打开 App，窗外在下雨。
          </p>
        </div>

        {/* 右：温度 — 视觉炸弹 */}
        <div className="flex flex-1 items-end justify-center md:justify-end md:pr-4">
          <div className="flex items-start gap-1">
            <Counter
              value={26}
              duration={2200}
              className="font-en text-[7rem] font-black leading-none text-accent-honey md:text-[11rem] lg:text-[14rem]"
            />
            <span className="mt-4 text-2xl font-light text-text-secondary md:mt-8 md:text-4xl lg:mt-12 lg:text-5xl">
              °C
            </span>
          </div>
        </div>
      </div>
    </section>
  );
}
