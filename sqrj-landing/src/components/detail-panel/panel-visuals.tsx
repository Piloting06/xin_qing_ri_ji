"use client";

export type PanelType = "weather" | "mood" | "card" | "city" | "capsule" | "social" | "theme";

const COLORS: Record<PanelType, { bg: string; accent: string; soft: string }> = {
  weather: { bg: "#EDD5BF", accent: "#C49060", soft: "#DFC5A5" },
  mood:    { bg: "#F0D2D2", accent: "#C48888", soft: "#E0B8B8" },
  card:    { bg: "#EDD5B5", accent: "#D4A060", soft: "#DFC09A" },
  city:    { bg: "#DFD0BC", accent: "#A89070", soft: "#C8B8A0" },
  capsule: { bg: "#E8D2C0", accent: "#C49870", soft: "#D8BCA0" },
  social:  { bg: "#E5CCC5", accent: "#C09080", soft: "#D5B5AA" },
  theme:   { bg: "#E5CDB5", accent: "#D09060", soft: "#D8BB9A" },
};

function WeatherVisual({ c }: { c: { bg: string; accent: string; soft: string } }) {
  return (
    <div className="relative flex h-40 items-center justify-center overflow-hidden rounded-2xl" style={{ backgroundColor: c.bg }}>
      {/* 云 */}
      <div className="absolute left-4 top-6 h-10 w-20 rounded-full" style={{ backgroundColor: c.soft, opacity: 0.5 }} />
      <div className="absolute right-6 top-10 h-8 w-16 rounded-full" style={{ backgroundColor: c.soft, opacity: 0.4 }} />
      <div className="absolute left-1/3 bottom-8 h-6 w-14 rounded-full" style={{ backgroundColor: c.soft, opacity: 0.3 }} />
      {/* 温度 */}
      <span className="relative font-en text-6xl font-black" style={{ color: c.accent }}>26°C</span>
    </div>
  );
}

function MoodVisual({ c }: { c: { bg: string; accent: string; soft: string } }) {
  const moods = ["😊", "😐", "😢", "😤"];
  return (
    <div className="flex h-40 items-center justify-center gap-5 rounded-2xl" style={{ backgroundColor: c.bg }}>
      {moods.map((m, i) => (
        <div key={i} className="flex h-14 w-14 items-center justify-center rounded-full text-2xl" style={{ backgroundColor: i === 0 ? c.accent : c.soft, opacity: i === 0 ? 1 : 0.5 }}>
          {m}
        </div>
      ))}
    </div>
  );
}

function CardVisual({ c }: { c: { bg: string; accent: string; soft: string } }) {
  return (
    <div className="flex h-40 items-center justify-center rounded-2xl" style={{ backgroundColor: c.bg }}>
      <div className="h-28 w-44 rounded-xl border p-4 shadow-md" style={{ borderColor: c.accent + "40", backgroundColor: "#FFFCF8" }}>
        <div className="flex items-center gap-2 mb-3">
          <div className="h-4 w-4 rounded-full" style={{ backgroundColor: c.accent }} />
          <span className="font-en text-[10px] text-text-muted">2026.05.28</span>
        </div>
        <div className="h-1.5 w-3/4 rounded mb-1.5" style={{ backgroundColor: c.soft }} />
        <div className="h-1.5 w-1/2 rounded mb-4" style={{ backgroundColor: c.soft, opacity: 0.6 }} />
        <div className="flex gap-1">
          <div className="h-1.5 w-1.5 rounded-full" style={{ backgroundColor: c.accent }} />
          <div className="h-1.5 w-1.5 rounded-full" style={{ backgroundColor: c.accent, opacity: 0.5 }} />
          <div className="h-1.5 w-1.5 rounded-full" style={{ backgroundColor: c.accent, opacity: 0.3 }} />
        </div>
      </div>
    </div>
  );
}

function CityVisual({ c }: { c: { bg: string; accent: string; soft: string } }) {
  const cities = [
    { name: "北京", x: 20, y: 25 }, { name: "上海", x: 70, y: 55 },
    { name: "广州", x: 55, y: 80 }, { name: "成都", x: 30, y: 60 },
    { name: "杭州", x: 75, y: 35 }, { name: "武汉", x: 50, y: 45 },
  ];
  return (
    <div className="relative h-40 overflow-hidden rounded-2xl" style={{ backgroundColor: c.bg }}>
      {cities.map((city, i) => (
        <div key={i} className="absolute flex flex-col items-center" style={{ left: `${city.x}%`, top: `${city.y}%` }}>
          <div className="h-2 w-2 rounded-full" style={{ backgroundColor: c.accent }} />
          <span className="mt-0.5 text-[8px] text-text-muted">{city.name}</span>
        </div>
      ))}
    </div>
  );
}

function CapsuleVisual({ c }: { c: { bg: string; accent: string; soft: string } }) {
  return (
    <div className="flex h-40 items-center justify-center rounded-2xl" style={{ backgroundColor: c.bg }}>
      <div className="relative flex h-24 w-48 items-center justify-center rounded-full border-2" style={{ borderColor: c.accent, backgroundColor: "#FFFCF8" }}>
        <div className="absolute -top-1 left-1/2 h-2 w-16 -translate-x-1/2 rounded-full" style={{ backgroundColor: c.accent }} />
        <span className="font-en text-2xl font-bold" style={{ color: c.accent }}>365 天</span>
      </div>
    </div>
  );
}

function SocialVisual({ c }: { c: { bg: string; accent: string; soft: string } }) {
  const notes = [
    { text: "有人在吗", x: 10, y: 15, r: -5 },
    { text: "想回家", x: 55, y: 10, r: 3 },
    { text: "晚安", x: 30, y: 55, r: -8 },
    { text: "撑过去了", x: 60, y: 55, r: 6 },
  ];
  return (
    <div className="relative h-40 overflow-hidden rounded-2xl" style={{ backgroundColor: c.bg }}>
      {notes.map((n, i) => (
        <div key={i} className="absolute w-20 rounded-lg border px-2.5 py-1.5 shadow-sm" style={{ left: `${n.x}%`, top: `${n.y}%`, transform: `rotate(${n.r}deg)`, borderColor: c.accent + "30", backgroundColor: "#FFFCF8" }}>
          <span className="text-[9px] text-text-secondary">{n.text}</span>
        </div>
      ))}
    </div>
  );
}

function ThemeVisual({ c }: { c: { bg: string; accent: string; soft: string } }) {
  const themes = [
    { bg: "#FFF8F0", label: "暖白" },
    { bg: "#0A1120", label: "深蓝" },
    { bg: "#EAF5F3", label: "薄荷" },
    { bg: "#F8F0F0", label: "柔粉" },
  ];
  return (
    <div className="flex h-40 items-center justify-center gap-3 rounded-2xl" style={{ backgroundColor: c.bg }}>
      {themes.map((t, i) => (
        <div key={i} className="flex flex-col items-center gap-1.5">
          <div className="h-14 w-10 rounded-lg shadow-sm" style={{ backgroundColor: t.bg, border: i === 0 ? `2px solid ${c.accent}` : "1px solid #ddd" }} />
          <span className="text-[8px] text-text-muted">{t.label}</span>
        </div>
      ))}
    </div>
  );
}

const VISUALS: Record<PanelType, React.FC<{ c: { bg: string; accent: string; soft: string } }>> = {
  weather: WeatherVisual,
  mood: MoodVisual,
  card: CardVisual,
  city: CityVisual,
  capsule: CapsuleVisual,
  social: SocialVisual,
  theme: ThemeVisual,
};

export function PanelVisual({ type }: { type: PanelType }) {
  const Visual = VISUALS[type];
  const c = COLORS[type];
  return <Visual c={c} />;
}

export function getPanelColors(type: PanelType) {
  return COLORS[type];
}
