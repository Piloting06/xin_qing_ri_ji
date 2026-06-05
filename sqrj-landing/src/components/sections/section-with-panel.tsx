"use client";

import { useState } from "react";
import { FeaturePanel } from "@/components/detail-panel/feature-panel";
import { TitleClickProvider } from "@/components/title-click-context";
import type { PanelType } from "@/components/detail-panel/panel-visuals";

interface PanelData {
  title: string;
  why: string;
  howTo: string;
  type: PanelType;
}

interface SectionWithPanelProps {
  panel: PanelData;
  children: React.ReactNode;
}

export function SectionWithPanel({ panel, children }: SectionWithPanelProps) {
  const [open, setOpen] = useState(false);

  return (
    <TitleClickProvider onClick={() => setOpen(true)}>
      <div className="relative">
        {children}
        <FeaturePanel
          isOpen={open}
          onClose={() => setOpen(false)}
          title={panel.title}
          why={panel.why}
          howTo={panel.howTo}
          type={panel.type}
        />
      </div>
    </TitleClickProvider>
  );
}
