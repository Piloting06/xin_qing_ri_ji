"use client";

import { useRef } from "react";
import { motion, useTransform } from "motion/react";
import { GlowButton } from "@/components/ui/glow-button";
import { useSectionScroll } from "@/components/use-section-scroll";
import Image from "next/image";

export function DownloadSection() {
  const sectionRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useSectionScroll({
    target: sectionRef,
    offset: ["start end", "end start"],
  });

  const iconOpacity = useTransform(scrollYProgress, [0.2, 0.35], [0, 1]);
  const iconScale = useTransform(scrollYProgress, [0.2, 0.35], [0.8, 1]);
  const titleOpacity = useTransform(scrollYProgress, [0.3, 0.4], [0, 1]);
  const titleY = useTransform(scrollYProgress, [0.3, 0.4], [20, 0]);
  const buttonOpacity = useTransform(scrollYProgress, [0.4, 0.5], [0, 1]);
  const buttonY = useTransform(scrollYProgress, [0.4, 0.5], [20, 0]);

  return (
    <section
      ref={sectionRef}
      className="relative flex min-h-[80vh] flex-col items-center justify-center overflow-hidden bg-bg-cream px-6 md:px-16 lg:px-24"
    >
      <div className="relative z-10 flex flex-col items-center gap-10">
        {/* App 图标 */}
        <motion.div style={{ opacity: iconOpacity, scale: iconScale }}>
          <Image
            src="/screenshots/app-icon.png"
            alt="拾晴日记"
            width={72}
            height={72}
            className="rounded-2xl shadow-lg shadow-accent-honey/10 md:h-[88px] md:w-[88px]"
          />
        </motion.div>

        <motion.h2
          className="font-cn text-center text-3xl font-bold text-text-primary md:text-4xl lg:text-5xl"
          style={{ opacity: titleOpacity, y: titleY }}
        >
          给你的礼物。
        </motion.h2>

        <motion.div style={{ opacity: buttonOpacity, y: buttonY }}>
          <GlowButton href="/sqrj.apk" download>
            拆开看看。
          </GlowButton>
        </motion.div>
      </div>
    </section>
  );
}
