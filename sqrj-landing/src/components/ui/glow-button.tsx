"use client";

import { motion } from "motion/react";
import { type ReactNode } from "react";

interface GlowButtonProps {
  children: ReactNode;
  href?: string;
  download?: boolean;
  onClick?: () => void;
  className?: string;
}

/**
 * 发光按钮组件。
 * 蜂蜜色描边，hover 缓慢填满，克制但有温度。
 */
export function GlowButton({
  children,
  href,
  download = false,
  onClick,
  className = "",
}: GlowButtonProps) {
  const Component = href ? motion.a : motion.button;

  const props = href
    ? { href, download: download ? "" : undefined }
    : { onClick };

  return (
    <Component
      className={`
        relative inline-flex items-center justify-center
        rounded-full border border-accent-honey/60
        px-10 py-4 text-lg tracking-wide text-text-primary
        overflow-hidden cursor-pointer
        transition-colors duration-300
        ${className}
      `}
      whileHover="hover"
      whileTap={{ scale: 0.97 }}
      initial="rest"
      variants={{
        rest: {
          backgroundColor: "transparent",
          borderColor: "rgba(240,178,122,0.6)",
        },
        hover: {
          backgroundColor: "rgba(240,178,122,0.12)",
          borderColor: "rgba(240,178,122,1)",
        },
      }}
      transition={{ duration: 0.4, ease: [0.25, 1, 0.5, 1] }}
      {...props}
    >
      {/* 内部填满动画层 */}
      <motion.span
        className="absolute inset-0 rounded-full bg-accent-honey/10"
        initial={{ scaleX: 0, originX: 0 }}
        variants={{
          rest: { scaleX: 0 },
          hover: { scaleX: 1 },
        }}
        transition={{ duration: 0.6, ease: [0.25, 1, 0.5, 1] }}
      />
      <span className="relative z-10">{children}</span>
    </Component>
  );
}
