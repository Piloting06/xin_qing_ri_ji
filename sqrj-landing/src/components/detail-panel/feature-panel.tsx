"use client";

import { motion, AnimatePresence } from "motion/react";
import { PanelVisual, getPanelColors, type PanelType } from "./panel-visuals";

interface FeaturePanelProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  why: string;
  howTo: string;
  type: PanelType;
}

export function FeaturePanel({
  isOpen,
  onClose,
  title,
  why,
  howTo,
  type,
}: FeaturePanelProps) {
  const colors = getPanelColors(type);

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
          />
          <motion.div
            className="fixed inset-x-0 bottom-0 top-12 z-50 overflow-y-auto rounded-t-3xl"
            style={{ backgroundColor: colors.bg }}
            initial={{ y: "100%" }}
            animate={{ y: 0 }}
            exit={{ y: "100%" }}
            transition={{ type: "spring", damping: 30, stiffness: 300 }}
            drag="y"
            dragConstraints={{ top: 0 }}
            onDragEnd={(_, info) => {
              if (info.offset.y > 120 || info.velocity.y > 500) onClose();
            }}
          >
            {/* 拖拽条 */}
            <div className="sticky top-0 z-10 flex justify-center pt-4 pb-2" style={{ backgroundColor: colors.bg }}>
              <div className="h-1 w-10 rounded-full" style={{ backgroundColor: colors.accent + "30" }} />
            </div>

            {/* 关闭按钮 */}
            <button
              onClick={onClose}
              className="absolute top-5 right-5 z-20 flex h-11 w-11 items-center justify-center rounded-full transition-colors"
              style={{ color: colors.accent }}
              aria-label="关闭"
            >
              ✕
            </button>

            <div className="mx-auto max-w-lg px-6 pb-16 space-y-8 md:px-8">
              {/* 标题 */}
              <h3 className="font-cn text-2xl font-bold text-text-primary pr-12 md:text-3xl">
                {title}
              </h3>

              {/* 为什么 */}
              <div className="space-y-3">
                <div className="flex items-center gap-2">
                  <div className="h-px flex-1" style={{ backgroundColor: colors.accent + "30" }} />
                  <span className="font-en text-xs tracking-[0.25em] uppercase" style={{ color: colors.accent }}>
                    为什么
                  </span>
                  <div className="h-px flex-1" style={{ backgroundColor: colors.accent + "30" }} />
                </div>
                <p className="text-base leading-[2] text-text-secondary">
                  {why}
                </p>
              </div>

              {/* 功能图画 */}
              <PanelVisual type={type} />

              {/* 怎么用 */}
              <div className="space-y-3">
                <div className="flex items-center gap-2">
                  <div className="h-px flex-1" style={{ backgroundColor: colors.accent + "30" }} />
                  <span className="font-en text-xs tracking-[0.25em] uppercase" style={{ color: colors.accent }}>
                    怎么用
                  </span>
                  <div className="h-px flex-1" style={{ backgroundColor: colors.accent + "30" }} />
                </div>
                <p className="text-base leading-[2] text-text-secondary">
                  {howTo}
                </p>
              </div>

              {/* 底部提示 */}
              <div className="flex items-center justify-center gap-2 pt-4">
                <div className="h-px w-8" style={{ backgroundColor: colors.accent + "20" }} />
                <span className="text-[10px] tracking-widest" style={{ color: colors.accent + "60" }}>
                  下滑关闭
                </span>
                <div className="h-px w-8" style={{ backgroundColor: colors.accent + "20" }} />
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
