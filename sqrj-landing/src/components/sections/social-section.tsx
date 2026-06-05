"use client";

import { useState, useEffect } from "react";
import { motion } from "motion/react";
import { useTitleClick } from "@/components/title-click-context";
import { TextSplitReveal } from "@/components/ui/text-split-reveal";

const NOTES = [
  { text: "今天终于拿到offer了" },
  { text: "考研上岸！" },
  { text: "分手第三天，还是会想她" },
  { text: "淋了一场雨，但心情还不错" },
  { text: "失眠了，有人醒着吗" },
  { text: "一个人吃了火锅" },
];

function CloudIcon({ type, delay = 0 }: { type: "hug" | "coffee"; delay?: number }) {
  const paths = {
    hug: (
      <>
        <circle cx="20" cy="20" r="16" className="stroke-accent-honey/40" />
        <path d="M14 18 Q16 14 20 16 Q24 14 26 18" className="stroke-accent-honey/60" />
        <path d="M15 24 Q20 28 25 24" className="stroke-accent-honey/60" />
      </>
    ),
    coffee: (
      <>
        <rect x="10" y="16" width="20" height="14" rx="2" className="stroke-accent-mint/40" />
        <path d="M30 20 Q34 20 34 24 Q34 28 30 28" className="stroke-accent-mint/40" />
        <path d="M14 14 Q16 10 18 14" className="stroke-accent-mint/50" />
        <path d="M20 14 Q22 10 24 14" className="stroke-accent-mint/50" />
      </>
    ),
  };

  return (
    <motion.div
      className="flex h-12 w-12 items-center justify-center rounded-full border border-accent-honey/10 bg-bg-card/50 backdrop-blur-sm"
      animate={{ y: [0, -4, 0] }}
      transition={{ repeat: Infinity, duration: 1.2, delay, ease: "easeInOut" }}
    >
      <svg
        viewBox="0 0 40 40"
        className="h-6 w-6"
        fill="none"
        strokeWidth="1.5"
        strokeLinecap="round"
      >
        {paths[type]}
      </svg>
    </motion.div>
  );
}

export function SocialSection() {
  const onTitleClick = useTitleClick();

  // 随机布局 — SSR 和客户端初始值一致，mount 后再随机化
  const [layouts, setLayouts] = useState(() =>
    NOTES.map((_, i) => ({
      x: 10 + i * 14,
      y: 10 + (i % 3) * 25,
      rotate: -8 + i * 3,
    }))
  );

  useEffect(() => {
    setLayouts(
      NOTES.map(() => ({
        x: 5 + Math.random() * 70,
        y: 5 + Math.random() * 75,
        rotate: -12 + Math.random() * 24,
      }))
    );
  }, []);

  return (
    <section
      className="relative flex flex-col items-start overflow-hidden px-6 py-24 md:px-16 md:py-32 lg:px-24"
      style={{ backgroundColor: "#E5CCC5" }}
    >
      <div className="relative z-10 flex w-full flex-col gap-12">
        <div className="text-center md:text-left">
          <button type="button" onClick={() => onTitleClick?.()} className="font-cn text-2xl font-bold text-text-primary md:text-3xl lg:text-4xl cursor-pointer transition-all hover:text-accent-orange hover:tracking-wide">
            <TextSplitReveal text="有人醒着吗。" from="center" stagger={0.05} />
          </button>
          <p className="mt-4 max-w-sm text-sm leading-relaxed text-text-secondary md:mt-5 md:text-base mx-auto md:mx-0">
            匿名的。温暖的。不会评判你的。
          </p>
          <div className="flex flex-wrap gap-2 mt-4">
            {["不认识但不孤单", "一个拥抱不用说话", "深夜的一杯热咖啡", "真正关心你的人"].map(tag => (
              <span key={tag} className="px-3 py-1 rounded-full text-xs border" style={{ borderColor: "#C0908030", color: "#C09080" }}>
                {tag}
              </span>
            ))}
          </div>
          <p className="mt-4 text-xs leading-relaxed" style={{ color: "#C09080" }}>
            凌晨三点你睡不着，发了一条消息。三秒后，有人给你一个云拥抱。
          </p>
        </div>

        <div className="relative h-[420px] w-full md:h-[520px]">
          {NOTES.map((note, i) => {
            // 从中心向外的延迟 — 中间的先出现，两边的后出现
            const center = (NOTES.length - 1) / 2;
            const distance = Math.abs(i - center);
            const entranceDelay = 0.1 + distance * 0.1;

            return (
              <motion.div
                key={i}
                className="absolute"
                initial={{ opacity: 0 }}
                whileInView={{ opacity: 1 }}
                viewport={{ once: true, amount: 0.3 }}
                transition={{ duration: 0.6, delay: entranceDelay, ease: [0.25, 1, 0.5, 1] }}
                style={{
                  left: `${layouts[i].x}%`,
                  top: `${layouts[i].y}%`,
                }}
              >
                <motion.div
                  animate={{
                    y: [0, -6 - i * 2, 0],
                    rotate: [layouts[i].rotate, layouts[i].rotate + 2, layouts[i].rotate],
                  }}
                  transition={{
                    repeat: Infinity,
                    duration: 4 + i * 0.8,
                    delay: i * 0.5,
                    ease: "easeInOut",
                  }}
                >
                  <div className="w-44 rounded-xl border border-text-secondary/10 bg-bg-card/80 px-4 py-4 shadow-lg backdrop-blur-sm md:w-52">
                    <p className="text-sm leading-relaxed text-text-secondary/90 md:text-base">
                      <span className="mr-0.5 text-accent-honey/50">&quot;</span>
                      {note.text}
                      <span className="ml-0.5 text-accent-honey/50">&quot;</span>
                    </p>
                  </div>
                </motion.div>
              </motion.div>
            );
          })}
        </div>

        <motion.div
          className="flex items-center gap-4"
          initial={{ scale: 0, opacity: 0 }}
          whileInView={{ scale: 1, opacity: 1 }}
          viewport={{ once: true, amount: 0.3 }}
          transition={{ duration: 0.6, delay: 0.5, ease: [0.25, 1, 0.5, 1] }}
        >
          <CloudIcon type="hug" />
          <CloudIcon type="coffee" delay={0.3} />
        </motion.div>
      </div>
    </section>
  );
}
