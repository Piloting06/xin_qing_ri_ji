"use client";

import { FrontPage } from "@/components/front-page";
import { HeroSection } from "@/components/hero/hero-section";
import { WeatherSection } from "@/components/sections/weather-section";
import { MoodSection } from "@/components/sections/mood-section";
import { CardSection } from "@/components/sections/card-section";
import { CitySection } from "@/components/sections/city-section";
import { CapsuleSection } from "@/components/sections/capsule-section";
import { SocialSection } from "@/components/sections/social-section";
import { ThemeSection } from "@/components/sections/theme-section";
import { DownloadSection } from "@/components/sections/download-section";
import { FloatingNav } from "@/components/nav/floating-nav";
import { CustomCursor } from "@/components/ui/custom-cursor";
import { SectionWithPanel } from "@/components/sections/section-with-panel";
import { ScrollContainerProvider, useScrollContainerRef } from "@/components/scroll-container-context";
import { AtmosphereLayer } from "@/components/atmosphere-layer";

const PANELS = {
  weather: {
    type: "weather" as const,
    title: "又下雨了。",
    why: "天气影响你穿什么、想不想出门、晚上能不能睡好。但我们很少主动去看天气——直到被淋了才想起来。把天气放在首页，是希望你每天打开日记的第一眼，就能看到窗外的样子。不用搜，不用点，它就在那里。这是你和今天的第一句对话。",
    howTo: "打开拾晴日记，首页就是当天的天气。自动定位你的城市，GPS 信号不好就用 IP 地址兜底，离线也有上次缓存的数据。往上滑，开始记录今天的心情。天气和心情，本来就是一件事。",
  },
  mood: {
    type: "mood" as const,
    title: "今天的心情，值得被记住。",
    why: "我们每天都有情绪，但从不主动记录。开心的事转头就忘，难过的事反复咀嚼。回看的时候才发现——原来上周三那么开心，原来月初那几天压力这么大。情绪不是虚无缥缈的东西，它是你生活的底色。记下来，才能看见自己。",
    howTo: "选一个最接近你现在的情绪——开心、平静、难过、烦躁，或者你自己定义。写几句想说的话，保存。一天可以记多条，没有字数限制。想写一个字就写一个字，想写一千字也没人拦你。三个月后回看，你会发现一条完整的情绪曲线。",
  },
  card: {
    type: "card" as const,
    title: "把心情变成一张卡片。",
    why: "文字日记是私人的，但有些心情你想分享给在乎的人。不是发朋友圈那种表演式的分享，而是真正想让某个人看到的那种。卡片就是那张图——把今天的心情、天气、日期，变成一张好看的东西。发给 Ta，不用多说一个字。",
    howTo: "记录心情后，点「制作卡片」。选一个主题色——暖白、深蓝、薄荷、柔粉。选一个形状。卡片自动生成，保存到相册，或者直接分享给微信好友、QQ 好友。收到的人看到的不是一条消息，是一张有温度的卡片。",
  },
  city: {
    type: "city" as const,
    title: "三百座城市，无数种心情。",
    why: "我们生活在各自的城市里，但情绪是相通的。你开心的时候，也许广州的某个人也在笑。你失眠的时候，也许成都的某个人也在发呆。城迹让你看到——全国 65 座城市里，其他人在说什么。不是社交，是共振。你不是一个人。",
    howTo: "打开城迹，看到一张光点地图。每个光点是一座城市，点进去，看到那座城市里最近的匿名留言。写下你自己的话，它会出现在你所在的城市里。没有人知道你是谁，但有人会看到。",
  },
  capsule: {
    type: "capsule" as const,
    title: "写给未来的自己。",
    why: "有些话只想跟未来的自己说。不是发朋友圈，不是写备忘录，就是封起来，等那天到了再打开。三个月后的你会怎么想？一年后的你还记得今天吗？时光胶囊不回答这些问题，它只是帮你把今天的自己，完整地交给未来的你。",
    howTo: "写一段文字——随便什么都行，一句话、一段心情、一个秘密。选封存天数：7 天、30 天、90 天、365 天。确认后，胶囊封存。到期前不能偷看。到期那天，你会收到一条通知：「你有一颗胶囊到期了。」打开它，看看过去的自己。",
  },
  social: {
    type: "social" as const,
    title: "不认识，但好像也不孤单。",
    why: "有些话不想让认识的人看到，但又想被听到。凌晨三点睡不着，想找个人说话，翻遍通讯录不知道打给谁。树洞就是这样的地方——匿名的、温暖的、不会评判你的。你发一条消息，也许有人给你一个云拥抱。好友功能则是给真正关心你的人开一扇窗。",
    howTo: "树洞里匿名发帖，不需要注册，不需要头像。看到别人的帖子，可以云拥抱，也可以云咖啡。好友功能通过手机号添加，互为好友后可以看对方的心情记录，互发纸条。两个世界，一个 App。",
  },
  theme: {
    type: "theme" as const,
    title: "四种颜色，四种心情。",
    why: "每个人打开日记的心情不一样。有时候想在阳光里写，有时候想在深夜里写。四套主题不是简单的换色——每套都有自己的性格。晴日暖白像清晨，静夜深蓝像深夜，雾感薄荷像雨后，豆沙柔粉像傍晚。跟着你的感觉走。",
    howTo: "在个人中心 → 外观与偏好里切换主题。点击已选中的主题，还能看到它的创作故事——为什么选这个颜色，它代表什么情绪。切换是即时的，不需要重启。",
  },
};

export default function Home() {
  return (
    <ScrollContainerProvider>
      <HomeContent />
    </ScrollContainerProvider>
  );
}

function HomeContent() {
  const scrollContainerRef = useScrollContainerRef();

  return (
    <main ref={scrollContainerRef} className="relative snap-container">
      <CustomCursor />
      <AtmosphereLayer />
      <FloatingNav />

      {/* Front download page */}
      <section className="snap-section">
        <FrontPage />
      </section>

      {/* Gradient transition — orange to cream */}
      <div
        id="transition"
        className="relative h-[200px] bg-gradient-to-b from-accent-orange via-accent-orange/40 to-bg-cream pointer-events-none"
      />

      <HeroSection />

      <div id="weather" className="snap-section">
        <SectionWithPanel panel={PANELS.weather}>
          <WeatherSection />
        </SectionWithPanel>
      </div>

      {/* 天气 → 心情 */}
      <div className="pointer-events-none h-20" style={{ background: "linear-gradient(to bottom, #EDD5BF, #F0D2D2)" }} />

      <div id="mood" className="snap-section">
        <SectionWithPanel panel={PANELS.mood}>
          <MoodSection />
        </SectionWithPanel>
      </div>

      {/* 心情 → 卡片 */}
      <div className="pointer-events-none h-20" style={{ background: "linear-gradient(to bottom, #F0D2D2, #EDD5B5)" }} />

      <div id="card" className="snap-section">
        <SectionWithPanel panel={PANELS.card}>
          <CardSection />
        </SectionWithPanel>
      </div>

      {/* 卡片 → 城迹 */}
      <div className="pointer-events-none h-20" style={{ background: "linear-gradient(to bottom, #EDD5B5, #DFD0BC)" }} />

      <div id="city" className="snap-section">
        <SectionWithPanel panel={PANELS.city}>
          <CitySection />
        </SectionWithPanel>
      </div>

      {/* 城迹 → 胶囊 */}
      <div className="pointer-events-none h-20" style={{ background: "linear-gradient(to bottom, #DFD0BC, #E8D2C0)" }} />

      <div id="capsule" className="snap-section">
        <SectionWithPanel panel={PANELS.capsule}>
          <CapsuleSection />
        </SectionWithPanel>
      </div>

      {/* 胶囊 → 社交 */}
      <div className="pointer-events-none h-20" style={{ background: "linear-gradient(to bottom, #E8D2C0, #E5CCC5)" }} />

      <div id="social" className="snap-section">
        <SectionWithPanel panel={PANELS.social}>
          <SocialSection />
        </SectionWithPanel>
      </div>

      {/* 社交 → 主题 */}
      <div className="pointer-events-none h-20" style={{ background: "linear-gradient(to bottom, #E5CCC5, #E5CDB5)" }} />

      <div id="theme" className="snap-section">
        <SectionWithPanel panel={PANELS.theme}>
          <ThemeSection />
        </SectionWithPanel>
      </div>

      <DownloadSection />

      <footer className="flex flex-col items-center gap-3 py-12 pb-24 sm:pb-12 text-xs text-text-muted">
        <div className="flex gap-4">
          <a href="#" className="py-2 px-3 hover:text-text-secondary transition-colors">
            GitHub
          </a>
          <a href="#" className="py-2 px-3 hover:text-text-secondary transition-colors">
            隐私政策
          </a>
          <a href="#" className="py-2 px-3 hover:text-text-secondary transition-colors">
            用户协议
          </a>
        </div>
        <span>© 2026 拾晴日记</span>
      </footer>
    </main>
  );
}
