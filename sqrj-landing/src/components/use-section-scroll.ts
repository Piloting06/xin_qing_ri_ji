"use client";

import { useScroll, type UseScrollOptions } from "motion/react";
import { useScrollContainerRef } from "./scroll-container-context";

/**
 * useScroll 包装 — 自动注入滚动容器 ref。
 * 用法与 motion 的 useScroll 完全一致，只是额外传了 container。
 */
export function useSectionScroll(opts?: UseScrollOptions) {
  const containerRef = useScrollContainerRef();
  return useScroll({
    ...opts,
    container: containerRef ?? undefined,
  });
}
