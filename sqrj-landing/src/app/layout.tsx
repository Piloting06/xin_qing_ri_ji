import type { Metadata } from "next";
import { Noto_Sans_SC, Inter } from "next/font/google";
import "./globals.css";

const zcool = {
  variable: "--font-zcool",
  style: { fontWeight: 400 as const, fontStyle: "normal" as const },
  display: "swap" as const,
  src: "url(https://p5.ssl.qhimg.com/t019cacc3b5cda33f90.woff2) format('woff2')",
};

const notoSansSC = Noto_Sans_SC({
  variable: "--font-noto-sans-sc",
  weight: ["300", "400", "500", "700", "900"],
  subsets: ["latin"],
  display: "swap",
});

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "拾晴日记 — 天气加心情",
  description: "天气加心情。写下来，发给Ta。",
  icons: {
    icon: "/screenshots/app-icon.png",
    apple: "/screenshots/app-icon.png",
  },
  openGraph: {
    title: "拾晴日记 — 记录天气，也记录你",
    description: "天气加心情。写下来，发给Ta。",
    url: "https://sqrj.hyfnoir.click",
    siteName: "拾晴日记",
    type: "website",
    locale: "zh_CN",
  },
  twitter: {
    card: "summary_large_image",
    title: "拾晴日记 — 记录天气，也记录你",
    description: "天气加心情。写下来，发给Ta。",
  },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html
      lang="zh-CN"
      className={`${zcool.variable} ${notoSansSC.variable} ${inter.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
