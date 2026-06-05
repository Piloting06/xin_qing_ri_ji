export const colors = {
  bg: {
    cream: "#FAFAF6",
    card: "#FFFFFF",
    warm: "#F5F0E8",
  },
  text: {
    primary: "#1C1C1E",
    secondary: "#6E6E73",
    muted: "#8E8E93",
  },
  accent: {
    orange: "#E8986E",
    honey: "#F0B27A",
    mint: "#7EC8C0",
    blush: "#D4A0A0",
    ink: "#3D3226",
  },
} as const;

export const spacing = {
  xs: 4, sm: 8, md: 16, lg: 24, xl: 40, "2xl": 64, "3xl": 96, "4xl": 128,
  sectionGap: 200, sectionGapMobile: 120,
} as const;

export const fontSize = {
  frontTitle: { mobile: 40, tablet: 52, desktop: 64 },
  hero: { mobile: 32, tablet: 40, desktop: 56 },
  sectionTitle: { mobile: 24, tablet: 28, desktop: 36 },
  body: { mobile: 14, tablet: 15, desktop: 16 },
  caption: { mobile: 12, tablet: 13, desktop: 14 },
} as const;

export const lineHeight = {
  frontTitle: 1.15,
  hero: 1.15,
  sectionTitle: 1.25,
  body: 1.65,
  caption: 1.5,
} as const;

export const breakpoints = { mobile: 375, tablet: 768, laptop: 1024, desktop: 1440 } as const;
