"use client";

import { useEffect, useState } from "react";
import { motion, useMotionValue, useSpring } from "motion/react";

export function CustomCursor() {
  const [mounted, setMounted] = useState(false);
  const [visible, setVisible] = useState(false);
  const x = useMotionValue(-100);
  const y = useMotionValue(-100);
  const sx = useSpring(x, { stiffness: 150, damping: 18, mass: 0.5 });
  const sy = useSpring(y, { stiffness: 150, damping: 18, mass: 0.5 });

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (!mounted) return;
    const move = (e: MouseEvent) => {
      x.set(e.clientX);
      y.set(e.clientY);
      if (!visible) setVisible(true);
    };
    const leave = () => setVisible(false);

    window.addEventListener("mousemove", move);
    document.body.addEventListener("mouseleave", leave);
    return () => {
      window.removeEventListener("mousemove", move);
      document.body.removeEventListener("mouseleave", leave);
    };
  }, [mounted, x, y, visible]);

  if (!mounted) return null;

  return (
    <>
      <motion.div
        className="pointer-events-none fixed top-0 left-0 z-[9999] h-3 w-3 rounded-full bg-accent-honey/80 mix-blend-multiply"
        style={{
          x: sx,
          y: sy,
          translateX: "-50%",
          translateY: "-50%",
          opacity: visible ? 1 : 0,
        }}
      />
      <motion.div
        className="pointer-events-none fixed top-0 left-0 z-[9999] h-10 w-10 rounded-full border border-accent-honey/30"
        style={{
          x: sx,
          y: sy,
          translateX: "-50%",
          translateY: "-50%",
          opacity: visible ? 1 : 0,
          scale: visible ? 1 : 0,
        }}
        transition={{ type: "spring", stiffness: 80, damping: 20 }}
      />
    </>
  );
}
