"use client";

import { useEffect, useRef } from "react";
import { motion, useAnimation } from "motion/react";

interface TransitionBridgeProps {
  type: "raindrops" | "card-to-dot" | "dots-to-capsule" | "capsule-to-note" | "hug-to-dot";
}

export function TransitionBridge({ type }: TransitionBridgeProps) {
  const controls = useAnimation();
  const hasRun = useRef(false);

  useEffect(() => {
    if (hasRun.current) return;
    hasRun.current = true;
    void controls.start("active");
  }, [controls, type]);

  if (type === "raindrops") {
    return (
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        {[0, 1, 2, 3, 4].map((i) => (
          <motion.div
            key={i}
            className="absolute h-1.5 w-4 rounded-full bg-accent-mint/30"
            style={{ left: `${12 + i * 18}%`, top: "-6px" }}
            variants={{
              active: {
                y: [0, 120, 160],
                scaleX: [1, 1, 8],
                scaleY: [1, 1, 0.3],
                opacity: [0.6, 0.5, 0.08],
              },
            }}
            transition={{ duration: 1.6, delay: i * 0.15, ease: "easeInOut" }}
            animate={controls}
          />
        ))}
      </div>
    );
  }

  if (type === "card-to-dot") {
    return (
      <div className="pointer-events-none absolute inset-0">
        <motion.div
          className="absolute left-1/2 top-1/2 h-16 w-12 -translate-x-1/2 -translate-y-1/2 rounded-xl bg-accent-honey/25"
          variants={{
            active: {
              x: [0, 80, 160],
              y: [0, -40, -100],
              rotate: [0, 6, 12],
              scale: [1, 0.7, 0.08],
              borderRadius: ["12px", "50%", "50%"],
              opacity: [0.5, 0.4, 0.25],
            },
          }}
          transition={{ duration: 1.8, ease: "easeInOut" }}
          animate={controls}
        />
        {/* 尾迹粒子 */}
        {[0, 1, 2].map((i) => (
          <motion.div
            key={i}
            className="absolute left-1/2 top-1/2 h-2 w-2 rounded-full bg-accent-honey/30"
            style={{ marginLeft: -4, marginTop: -4 }}
            variants={{
              active: {
                x: [0, 40 + i * 30, 100 + i * 20],
                y: [0, -20 - i * 25, -60 - i * 30],
                opacity: [0, 0.4, 0],
                scale: [0.5, 1, 0.3],
              },
            }}
            transition={{ duration: 1.8, delay: i * 0.2, ease: "easeInOut" }}
            animate={controls}
          />
        ))}
      </div>
    );
  }

  if (type === "dots-to-capsule") {
    return (
      <div className="pointer-events-none absolute inset-0">
        {[0, 1, 2, 3, 4, 5].map((i) => (
          <motion.div
            key={i}
            className="absolute h-2 w-2 rounded-full bg-accent-honey/40"
            style={{ left: `${15 + i * 14}%`, top: `${35 + i * 8}%` }}
            variants={{
              active: {
                x: [0, -10 * i + 30, 0],
                y: [0, -20, -80],
                scale: [1, 0.6, 0],
                opacity: [0.5, 0.3, 0],
              },
            }}
            transition={{ duration: 1.5, delay: i * 0.1, ease: "easeInOut" }}
            animate={controls}
          />
        ))}
      </div>
    );
  }

  if (type === "capsule-to-note") {
    return (
      <div className="pointer-events-none absolute inset-0">
        {[0, 1, 2].map((i) => (
          <motion.div
            key={i}
            className={`absolute h-${i === 0 ? "14" : "10"} w-${i === 0 ? "10" : "8"} rounded-lg bg-accent-blush/25`}
            style={{
              left: `${35 + i * 20}%`,
              top: "40%",
              rotate: -5 + i * 10,
            }}
            variants={{
              active: {
                y: [0, 20 + i * 30, 80 + i * 20],
                x: [0, 10 - i * 15, 0],
                rotate: [-5 + i * 10, -5 + i * 10 + 5, -5 + i * 10 - 3],
                opacity: [0, 0.4, 0.15],
              },
            }}
            transition={{ duration: 1.6, delay: i * 0.2, ease: "easeInOut" }}
            animate={controls}
          />
        ))}
      </div>
    );
  }

  if (type === "hug-to-dot") {
    return (
      <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
        <motion.div
          className="h-14 w-14 rounded-full border-2 border-accent-honey/30"
          variants={{
            active: { scale: [1, 0.3, 0.08], opacity: [0.5, 0.6, 0.3] },
          }}
          transition={{ duration: 1.2, ease: "easeInOut" }}
          animate={controls}
        />
        <motion.div
          className="absolute h-16 w-16 rounded-full border border-accent-mint/20"
          variants={{
            active: { scale: [0.8, 0.2, 0.05], opacity: [0.3, 0.4, 0] },
          }}
          transition={{ duration: 1.2, delay: 0.15, ease: "easeInOut" }}
          animate={controls}
        />
      </div>
    );
  }

  return null;
}
