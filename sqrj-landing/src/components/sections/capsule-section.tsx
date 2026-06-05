"use client";

import { useState } from "react";
import { motion, useSpring } from "motion/react";
import { Counter } from "@/components/ui/counter";
import { useTitleClick } from "@/components/title-click-context";

export function CapsuleSection() {
  const onTitleClick = useTitleClick();
  const [isInView, setIsInView] = useState(false);
  const lidRotate = useSpring(0, { stiffness: 80, damping: 18 });

  const handleViewportEnter = () => {
    setIsInView(true);
    lidRotate.set(-95);
  };

  return (
    <section
      className="relative flex flex-col overflow-hidden px-6 py-24 md:px-16 md:py-32 lg:px-24"
      style={{ backgroundColor: "#E8D2C0" }}
    >
      <div className="relative z-10 flex w-full flex-col items-center gap-12 md:flex-row-reverse md:items-center md:gap-8 lg:gap-16">
        {/* 右：标题 + 文字描述 */}
        <div className="flex-1 text-center md:text-right">
          <button type="button" onClick={() => onTitleClick?.()} className="font-cn text-2xl font-bold text-text-primary md:text-3xl lg:text-4xl cursor-pointer transition-all hover:text-accent-orange hover:tracking-wide">
            还没到打开的时候。
          </button>
          <p className="mt-4 max-w-sm text-sm leading-relaxed text-text-secondary md:mt-6 md:text-base mx-auto md:mx-0 md:ml-auto">
            有些话，只想跟未来的自己说。
          </p>
          <div className="flex flex-wrap gap-2 mt-4 md:justify-end">
            {["写给未来的自己", "到期那天你会收到通知", "封存了就不能偷看", "一句话也行"].map(tag => (
              <span key={tag} className="px-3 py-1 rounded-full text-xs border" style={{ borderColor: "#C4987030", color: "#C49870" }}>
                {tag}
              </span>
            ))}
          </div>
          <p className="mt-4 text-xs leading-relaxed md:text-right" style={{ color: "#C49870" }}>
            你写了一段话，封存了 90 天。到期那天，你收到一条通知。
          </p>
        </div>

        <div className="flex flex-1 flex-col items-center gap-8">
          {/* 胶囊 — 上下两半+密封条 */}
          <motion.div
            className="relative flex h-40 w-64 flex-col items-center justify-center md:h-48 md:w-80"
            onViewportEnter={handleViewportEnter}
            viewport={{ once: true, amount: 0.3 }}
          >
            {/* 下半部分 */}
            <div className="relative z-0 flex h-20 w-full items-center justify-center overflow-hidden rounded-b-full border border-accent-honey/15 bg-bg-card md:h-24">
              <div className="absolute inset-0 rounded-b-full bg-bg-card shadow-inner" />
            </div>

            {/* 胶囊内文字（在下半部分里） */}
            <motion.span
              className="absolute bottom-10 z-20 text-sm text-text-secondary/60 md:bottom-12 md:text-base"
              initial={{ opacity: 1 }}
              animate={isInView ? { opacity: 0 } : { opacity: 1 }}
              transition={{ duration: 0.8, ease: [0.25, 1, 0.5, 1] }}
            >
              撑过去了吗？
            </motion.span>

            {/* 密封条（文字消失后出现） */}
            <motion.div
              className="absolute top-1/2 z-20 h-0.5 w-[90%] -translate-y-1/2 bg-accent-honey/50"
              initial={{ scaleX: 0 }}
              whileInView={{ scaleX: 1 }}
              viewport={{ once: true, amount: 0.3 }}
              transition={{ duration: 0.6, delay: 0.3, ease: [0.25, 1, 0.5, 1] }}
              style={{ originX: 0.5 }}
            />

            {/* 上半部分 — 旋转闭合 */}
            <motion.div
              className="absolute top-0 z-10 flex h-20 w-full items-end justify-center overflow-hidden rounded-t-full border border-accent-honey/15 bg-bg-card md:h-24"
              style={{ originY: 1, rotateX: lidRotate }}
            >
              <div className="absolute inset-0 rounded-t-full bg-bg-card shadow-inner" />
            </motion.div>
          </motion.div>

          {/* 倒计时 — 大数字 */}
          <motion.div
            className="flex items-center gap-3"
            initial={{ opacity: 0, y: 10 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, amount: 0.3 }}
            transition={{ duration: 0.6, delay: 0.6, ease: [0.25, 1, 0.5, 1] }}
          >
            <Counter
              value={30}
              duration={1800}
              className="font-en text-6xl font-black text-accent-honey md:text-8xl lg:text-9xl"
            />
            <span className="text-sm text-text-muted md:text-base">天后打开</span>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
