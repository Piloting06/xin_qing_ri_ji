export default function Loading() {
  return (
    <div className="fixed inset-0 z-[9998] flex items-center justify-center bg-bg-cream">
      <div className="flex flex-col items-center gap-6">
        <div className="relative h-2 w-48 overflow-hidden rounded-full bg-text-secondary/10">
          <div
            className="absolute inset-y-0 animate-shimmer rounded-full bg-gradient-to-r from-transparent via-accent-honey/40 to-transparent"
            style={{
              backgroundSize: "200% 100%",
              animation: "shimmer 1.2s ease-in-out infinite",
            }}
          />
        </div>
        <span className="font-en text-[10px] tracking-[0.3em] text-text-muted">SQRJ</span>
      </div>
    </div>
  );
}
