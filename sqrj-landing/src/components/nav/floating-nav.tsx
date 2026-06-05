"use client";

import { useState, useEffect } from "react";
import { motion, useMotionValueEvent } from "motion/react";
import { useSectionScroll } from "@/components/use-section-scroll";

const NAV_ITEMS = [
  { id: "weather", label: "天气", icon: "☀" },
  { id: "mood", label: "心情", icon: "❤" },
  { id: "card", label: "卡片", icon: "◇" },
  { id: "city", label: "城迹", icon: "◎" },
  { id: "capsule", label: "胶囊", icon: "◆" },
  { id: "social", label: "社交", icon: "◉" },
];

export function FloatingNav() {
  const [visible, setVisible] = useState(false);
  const [activeSection, setActiveSection] = useState("");
  const { scrollY } = useSectionScroll();

  useMotionValueEvent(scrollY, "change", (latest) => {
    // 超过 80vh 才显示
    setVisible(latest > window.innerHeight * 0.8);
  });

  // 监听各 section 的位置，高亮当前 section
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setActiveSection(entry.target.id);
          }
        });
      },
      { threshold: 0.3, rootMargin: "-20% 0px -20% 0px" }
    );

    NAV_ITEMS.forEach(({ id }) => {
      const el = document.getElementById(id);
      if (el) observer.observe(el);
    });

    return () => observer.disconnect();
  }, []);

  const scrollTo = (id: string) => {
    document.getElementById(id)?.scrollIntoView({
      behavior: "smooth",
      block: "start",
    });
  };

  return (
    <motion.nav
      className="fixed bottom-0 inset-x-0 z-50 flex items-center justify-between px-4 py-3 sm:fixed sm:bottom-auto sm:top-0 sm:px-6 sm:py-4"
      style={{
        backgroundColor: "rgba(250,250,246,0.92)",
        backdropFilter: "blur(12px)",
      }}
      initial={{ opacity: 0 }}
      animate={{
        opacity: visible ? 1 : 0,
        y: visible ? 0 : 20,
      }}
      transition={{ duration: 0.4, ease: [0.25, 1, 0.5, 1] }}
    >
      {/* Logo — 手写风 */}
      <span className="hidden sm:block font-en text-sm font-light tracking-[0.15em] text-text-secondary/70">
        SQRJ
      </span>

      {/* 导航项 - desktop: 顶部横向全标签 */}
      <div className="hidden sm:flex items-center gap-6">
        {NAV_ITEMS.map(({ id, label }) => (
          <button
            key={id}
            onClick={() => scrollTo(id)}
            aria-label={label}
            className={`relative cursor-pointer text-sm transition-colors py-3 px-2 ${
              activeSection === id
                ? "text-accent-honey"
                : "text-text-secondary/60 hover:text-text-secondary"
            }`}
          >
            {label}
            {activeSection === id && (
              <motion.div
                className="absolute -bottom-1 left-0 h-px w-full bg-accent-honey"
                layoutId="nav-underline"
                transition={{ duration: 0.3, ease: [0.25, 1, 0.5, 1] }}
              />
            )}
          </button>
        ))}
      </div>

      {/* 导航项 - mobile: 底部 icon 横向排列 */}
      <div className="flex w-full items-center justify-around sm:hidden">
        {NAV_ITEMS.map(({ id, label, icon }) => (
          <button
            key={id}
            onClick={() => scrollTo(id)}
            aria-label={label}
            className={`relative flex flex-col items-center gap-0.5 cursor-pointer transition-colors py-1 px-1.5 ${
              activeSection === id
                ? "text-accent-honey"
                : "text-text-secondary/50 hover:text-text-secondary"
            }`}
          >
            <span className="text-base">{icon}</span>
            <span className="text-[10px] tracking-tight">{label}</span>
            {activeSection === id && (
              <motion.div
                className="absolute -bottom-0.5 left-1/2 h-0.5 w-5 -translate-x-1/2 rounded-full bg-accent-honey"
                layoutId="nav-underline-mobile"
                transition={{ duration: 0.3, ease: [0.25, 1, 0.5, 1] }}
              />
            )}
          </button>
        ))}
      </div>
    </motion.nav>
  );
}
