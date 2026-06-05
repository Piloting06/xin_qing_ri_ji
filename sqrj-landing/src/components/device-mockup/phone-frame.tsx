"use client";

import { motion } from "motion/react";
import Image from "next/image";

export function PhoneFrame({
  src,
  alt,
  className = "",
}: {
  src: string;
  alt: string;
  className?: string;
}) {
  return (
    <motion.div
      className={`relative ${className}`}
      initial={{ opacity: 0, scale: 0.95 }}
      whileInView={{ opacity: 1, scale: 1 }}
      viewport={{ once: true }}
      transition={{ duration: 0.6, ease: [0.25, 1, 0.5, 1] }}
    >
      {/* Glow behind */}
      <div className="absolute -inset-6 -z-10 rounded-3xl bg-accent-honey/5 blur-2xl" />
      {/* Phone body */}
      <div className="relative aspect-[9/16] w-48 overflow-hidden rounded-3xl border border-text-secondary/10 bg-bg-card md:w-56">
        <Image
          src={src}
          alt={alt}
          fill
          className="object-cover"
          sizes="(max-width: 768px) 192px, 224px"
        />
      </div>
    </motion.div>
  );
}
