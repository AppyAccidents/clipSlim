"use client";

import { useRef, useState, useCallback, useEffect } from "react";
import { toPng } from "html-to-image";

// Mac App Store screenshot size (Retina)
const W = 2880;
const H = 1800;

// Design tokens matching VibeCheck theme
const CYAN = "#00F5FF";
const ORANGE = "#FF8A00";
const BG_DARK = "#0A0A0F";
const BG_CARD = "#111118";
const TEXT_PRIMARY = "#EEEEF0";
const TEXT_SECONDARY = "#8888A0";

// Slide set type
type Slide = {
  id: string;
  label: string;
  headline: string;
  sub: string;
  images: string[];
  bg: string;
  pills?: string[];
};

type SlideSet = {
  id: string;
  name: string;
  description: string;
  promoText: string;
  slides: Slide[];
};

// All slide sets: Default + 3 Custom Product Pages
const SLIDE_SETS: SlideSet[] = [
  {
    id: "default",
    name: "Default",
    description: "Main App Store listing — broad appeal",
    promoText: "NEW: Native AVIF encoding, Shortcuts.app integration, and Finder Quick Action. The free clipboard image optimizer with zero limits. 100% local, 100% private.",
    slides: [
      {
        id: "hero",
        label: "Hero",
        headline: "Copy. Paste.\nAlready slim.",
        sub: "Automatic clipboard image optimization\nthat works while you work.",
        images: ["menubar", "overlay"],
        bg: `radial-gradient(ellipse 120% 80% at 50% 110%, ${CYAN}18 0%, transparent 60%), radial-gradient(ellipse 80% 60% at 80% 20%, ${ORANGE}12 0%, transparent 50%), linear-gradient(165deg, #0D0D14 0%, #0A0A0F 100%)`,
      },
      {
        id: "avif",
        label: "AVIF & Formats",
        headline: "AVIF, WebP, PNG.\nOne click away.",
        sub: "Native next-gen format encoding.\nNo cloud, no uploads, no waiting.",
        images: ["overlay"],
        bg: `radial-gradient(ellipse 100% 70% at 20% 90%, ${ORANGE}15 0%, transparent 50%), linear-gradient(165deg, #0F0D14 0%, #0A0A0F 100%)`,
      },
      {
        id: "history",
        label: "History",
        headline: "Every optimization,\nrecalled instantly.",
        sub: "Clipboard history with thumbnails.\nRe-paste any previous result.",
        images: ["history"],
        bg: `radial-gradient(ellipse 100% 80% at 60% 100%, ${CYAN}12 0%, transparent 50%), linear-gradient(165deg, #0A0D14 0%, #0A0A0F 100%)`,
      },
      {
        id: "rules",
        label: "App Rules",
        headline: "Figma gets high quality.\nSlack gets compressed.",
        sub: "Context-aware presets per app.\nNo other optimizer does this.",
        images: ["app-rules", "presets"],
        bg: `radial-gradient(ellipse 90% 70% at 30% 80%, ${ORANGE}14 0%, transparent 50%), radial-gradient(ellipse 60% 50% at 80% 30%, ${CYAN}08 0%, transparent 50%), linear-gradient(165deg, #0D0A14 0%, #0A0A0F 100%)`,
      },
      {
        id: "stats",
        label: "Stats & PDF",
        headline: "27 MB rescued.\nAnd counting.",
        sub: "Per-app stats, PDF compression,\nand folder watching — all automatic.",
        images: ["stats", "pdf"],
        bg: `radial-gradient(ellipse 100% 70% at 70% 90%, ${CYAN}14 0%, transparent 50%), linear-gradient(165deg, #0A0A14 0%, #0A0A0F 100%)`,
      },
      {
        id: "privacy",
        label: "Privacy & More",
        headline: "100% local.\nZero tracking.",
        sub: "Apple frameworks only. No network calls.\nNo accounts. Your clipboard is yours.",
        images: ["settings-general", "dropzone"],
        bg: `radial-gradient(ellipse 80% 60% at 50% 50%, ${CYAN}10 0%, transparent 60%), linear-gradient(165deg, #0A0D12 0%, #0A0A0F 100%)`,
        pills: ["Shortcuts.app", "Finder Quick Action", "Global Hotkeys", "Focus Mode", "Drop Zone", "Folder Rules"],
      },
    ],
  },
  {
    id: "cpp-webdev",
    name: "Web Developers",
    description: "CPP targeting web devs — AVIF, WebP, Shortcuts, automation",
    promoText: "Ship smaller images. Native AVIF and WebP encoding from your Mac menubar. Automatic clipboard optimization, Shortcuts automation, and Finder Quick Action. Free forever.",
    slides: [
      {
        id: "webdev-hero",
        label: "For Developers",
        headline: "Ship smaller assets.\nFrom your menubar.",
        sub: "Native AVIF and WebP encoding.\nNo cloud tools. No extra steps.",
        images: ["overlay"],
        bg: `radial-gradient(ellipse 120% 80% at 40% 110%, #6B21A818 0%, transparent 60%), radial-gradient(ellipse 80% 60% at 80% 20%, ${CYAN}15 0%, transparent 50%), linear-gradient(165deg, #0A0D14 0%, #0A0A0F 100%)`,
      },
      {
        id: "webdev-avif",
        label: "Next-Gen Formats",
        headline: "AVIF. WebP. HEIC.\nAll native.",
        sub: "Apple ImageIO under the hood.\n30-50% smaller than JPEG.",
        images: ["overlay"],
        bg: `radial-gradient(ellipse 100% 70% at 20% 90%, ${ORANGE}15 0%, transparent 50%), linear-gradient(165deg, #0F0D14 0%, #0A0A0F 100%)`,
      },
      {
        id: "webdev-shortcuts",
        label: "Automation",
        headline: "Shortcuts. Quick Action.\nZero friction.",
        sub: "OptimizeImageIntent for Apple Shortcuts.\nRight-click in Finder. Build pipelines.",
        images: ["presets", "settings-general"],
        bg: `radial-gradient(ellipse 90% 70% at 70% 80%, ${CYAN}14 0%, transparent 50%), linear-gradient(165deg, #0A0A14 0%, #0A0A0F 100%)`,
        pills: ["Shortcuts.app", "Finder Quick Action", "Folder Watcher", "Global Hotkeys"],
      },
      {
        id: "webdev-privacy",
        label: "Local & Free",
        headline: "No API keys.\nNo upload limits.",
        sub: "100% on-device with Apple frameworks.\nFree forever. No accounts.",
        images: ["stats"],
        bg: `radial-gradient(ellipse 80% 60% at 50% 50%, ${CYAN}10 0%, transparent 60%), linear-gradient(165deg, #0A0D12 0%, #0A0A0F 100%)`,
      },
    ],
  },
  {
    id: "cpp-designer",
    name: "Designers & Marketers",
    description: "CPP targeting designers — batch processing, presets, quality",
    promoText: "Every image you copy gets optimized automatically. Drag and drop batches, set quality presets per app, and compress PDFs. Made for creative workflows.",
    slides: [
      {
        id: "designer-hero",
        label: "For Creatives",
        headline: "Export from Figma.\nPaste it slim.",
        sub: "Automatic optimization on every copy.\nYour assets, always ready.",
        images: ["menubar", "overlay"],
        bg: `radial-gradient(ellipse 120% 80% at 50% 110%, ${ORANGE}18 0%, transparent 60%), radial-gradient(ellipse 80% 60% at 20% 20%, #E91E6312 0%, transparent 50%), linear-gradient(165deg, #140D0D 0%, #0A0A0F 100%)`,
      },
      {
        id: "designer-batch",
        label: "Batch Processing",
        headline: "100 files.\nDrag. Drop. Done.",
        sub: "Drop Zone accepts images and PDFs.\nFolder watcher runs in the background.",
        images: ["history"],
        bg: `radial-gradient(ellipse 100% 80% at 60% 100%, ${ORANGE}12 0%, transparent 50%), linear-gradient(165deg, #140D0A 0%, #0A0A0F 100%)`,
      },
      {
        id: "designer-presets",
        label: "Smart Presets",
        headline: "Web. Print. Social.\nOne preset each.",
        sub: "Quality presets with pipeline control.\nResize, strip metadata, convert format.",
        images: ["presets", "app-rules"],
        bg: `radial-gradient(ellipse 90% 70% at 30% 80%, ${ORANGE}14 0%, transparent 50%), linear-gradient(165deg, #0D0A14 0%, #0A0A0F 100%)`,
      },
      {
        id: "designer-pdf",
        label: "PDF & Quality",
        headline: "PDFs compressed.\nQuality protected.",
        sub: "SSIM quality guard ensures no degradation.\nPDF DPI control for print vs screen.",
        images: ["pdf", "stats"],
        bg: `radial-gradient(ellipse 100% 70% at 70% 90%, ${CYAN}14 0%, transparent 50%), linear-gradient(165deg, #0A0A14 0%, #0A0A0F 100%)`,
      },
    ],
  },
  {
    id: "cpp-poweruser",
    name: "Mac Power Users",
    description: "CPP targeting power users — automation, privacy, control",
    promoText: "Every image stays on your Mac. ClipSlim compresses clipboard images and PDFs locally — no cloud, no uploads, no accounts. Free with AVIF, WebP, HEIC support.",
    slides: [
      {
        id: "power-hero",
        label: "For Power Users",
        headline: "Your clipboard,\nsupercharged.",
        sub: "Automatic image optimization.\nMenubar control. Global hotkeys.",
        images: ["menubar", "overlay"],
        bg: `radial-gradient(ellipse 120% 80% at 50% 110%, ${CYAN}20 0%, transparent 60%), radial-gradient(ellipse 80% 60% at 80% 20%, #6B21A812 0%, transparent 50%), linear-gradient(165deg, #0D0D14 0%, #0A0A0F 100%)`,
      },
      {
        id: "power-rules",
        label: "Per-App Rules",
        headline: "Every app gets\nits own preset.",
        sub: "Figma: High Quality. Slack: Compressed.\nAuto-applied after 5 accepts.",
        images: ["app-rules", "presets"],
        bg: `radial-gradient(ellipse 90% 70% at 30% 80%, ${ORANGE}14 0%, transparent 50%), linear-gradient(165deg, #0D0A14 0%, #0A0A0F 100%)`,
      },
      {
        id: "power-stats",
        label: "Deep Stats",
        headline: "Every byte,\naccounted for.",
        sub: "Per-app savings breakdown.\nSession stats and optimization history.",
        images: ["stats", "history"],
        bg: `radial-gradient(ellipse 100% 70% at 70% 90%, ${CYAN}14 0%, transparent 50%), linear-gradient(165deg, #0A0A14 0%, #0A0A0F 100%)`,
      },
      {
        id: "power-privacy",
        label: "Private & Yours",
        headline: "No cloud. No telemetry.\nJust your Mac.",
        sub: "Built on Apple ImageIO and Core Graphics.\nFocus mode. Folder rules. Full control.",
        images: ["settings-general", "folders"],
        bg: `radial-gradient(ellipse 80% 60% at 50% 50%, ${CYAN}10 0%, transparent 60%), linear-gradient(165deg, #0A0D12 0%, #0A0A0F 100%)`,
        pills: ["Focus Mode", "Folder Rules", "Global Hotkeys", "Option+1 / Option+2", "Selective Metadata"],
      },
    ],
  },
];

function SlideContent({ slide, index, totalSlides }: { slide: Slide; index: number; totalSlides: number }) {
  const isHero = index === 0;
  const isLast = index === totalSlides - 1;

  return (
    <div
      style={{
        width: W,
        height: H,
        background: slide.bg,
        position: "relative",
        overflow: "hidden",
        fontFamily: "Inter, system-ui, -apple-system, sans-serif",
      }}
    >
      {/* Subtle grid texture */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          backgroundImage: `linear-gradient(${TEXT_SECONDARY}06 1px, transparent 1px), linear-gradient(90deg, ${TEXT_SECONDARY}06 1px, transparent 1px)`,
          backgroundSize: "60px 60px",
        }}
      />

      {/* Accent glow orb */}
      <div
        style={{
          position: "absolute",
          width: 600,
          height: 600,
          borderRadius: "50%",
          background: `radial-gradient(circle, ${CYAN}15, transparent 70%)`,
          top: isHero ? -200 : index % 2 === 0 ? -100 : "auto",
          bottom: index % 2 !== 0 ? -200 : "auto",
          left: isHero ? "10%" : index % 2 === 0 ? "auto" : "5%",
          right: index % 2 === 0 ? "5%" : "auto",
          filter: "blur(80px)",
        }}
      />

      {/* Text content */}
      <div
        style={{
          position: "absolute",
          top: isHero ? 180 : 140,
          left: 160,
          zIndex: 10,
          maxWidth: 1200,
        }}
      >
        {/* Slide number pill */}
        {!isHero && (
          <div
            style={{
              display: "inline-block",
              padding: "6px 20px",
              borderRadius: 100,
              background: `${CYAN}15`,
              border: `1px solid ${CYAN}30`,
              color: CYAN,
              fontSize: 28,
              fontWeight: 600,
              letterSpacing: 2,
              marginBottom: 32,
              textTransform: "uppercase",
            }}
          >
            {slide.label}
          </div>
        )}

        {/* App icon + name for hero */}
        {isHero && (
          <div style={{ display: "flex", alignItems: "center", gap: 24, marginBottom: 48 }}>
            <div
              style={{
                width: 80,
                height: 80,
                borderRadius: 18,
                background: `linear-gradient(135deg, ${BG_CARD}, #1a1a24)`,
                border: `2px solid ${CYAN}40`,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: 42,
              }}
            >
              ✂️
            </div>
            <div>
              <div style={{ color: TEXT_PRIMARY, fontSize: 36, fontWeight: 700 }}>ClipSlim</div>
              <div style={{ color: TEXT_SECONDARY, fontSize: 24 }}>Clipboard Optimizer for Mac</div>
            </div>
          </div>
        )}

        {/* Headline */}
        <div
          style={{
            fontSize: isHero ? 128 : 108,
            fontWeight: 800,
            color: TEXT_PRIMARY,
            lineHeight: 0.95,
            letterSpacing: -3,
            whiteSpace: "pre-line",
          }}
        >
          {slide.headline.split("\n").map((line, i) => (
            <span key={i}>
              {i > 0 && <br />}
              {i === 0 ? (
                line
              ) : (
                <span
                  style={{
                    background: `linear-gradient(90deg, ${CYAN}, ${CYAN}CC)`,
                    WebkitBackgroundClip: "text",
                    WebkitTextFillColor: "transparent",
                  }}
                >
                  {line}
                </span>
              )}
            </span>
          ))}
        </div>

        {/* Subheadline */}
        <div
          style={{
            fontSize: 38,
            color: TEXT_SECONDARY,
            lineHeight: 1.5,
            marginTop: 36,
            whiteSpace: "pre-line",
            maxWidth: 900,
          }}
        >
          {slide.sub}
        </div>

        {/* Pills for last slide */}
        {isLast && slide.pills && (
          <div style={{ display: "flex", flexWrap: "wrap", gap: 16, marginTop: 48, maxWidth: 800 }}>
            {slide.pills.map((pill) => (
              <div
                key={pill}
                style={{
                  padding: "12px 28px",
                  borderRadius: 100,
                  background: BG_CARD,
                  border: `1px solid ${TEXT_SECONDARY}30`,
                  color: TEXT_PRIMARY,
                  fontSize: 28,
                  fontWeight: 500,
                }}
              >
                {pill}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Screenshots - data-driven layout based on image count */}
      {slide.images.length === 2 && (
        <>
          <img
            src={`/screenshots/${slide.images[0]}.png`}
            alt={slide.images[0]}
            style={{
              position: "absolute",
              right: isHero ? 520 : 440,
              top: isHero ? 200 : 180,
              height: isHero ? 1500 : 1450,
              borderRadius: 24,
              boxShadow: `0 30px 100px rgba(0,0,0,0.5)`,
              transform: `rotate(${isHero ? -2 : -3}deg)`,
              opacity: isHero ? 0.85 : 0.7,
            }}
          />
          <img
            src={`/screenshots/${slide.images[1]}.png`}
            alt={slide.images[1]}
            style={{
              position: "absolute",
              right: 80,
              top: isHero ? 120 : 100,
              height: isHero ? 1600 : 1600,
              borderRadius: 24,
              boxShadow: `0 40px 120px rgba(0,0,0,0.7), 0 0 60px ${index % 2 === 0 ? ORANGE : CYAN}12`,
              border: `1px solid ${index % 2 === 0 ? ORANGE : CYAN}20`,
            }}
          />
        </>
      )}

      {slide.images.length === 1 && (
        <img
          src={`/screenshots/${slide.images[0]}.png`}
          alt={slide.images[0]}
          style={{
            position: "absolute",
            right: 100,
            top: "50%",
            transform: "translateY(-48%)",
            height: slide.images[0] === "history" ? 1350 : 1550,
            borderRadius: 24,
            boxShadow: `0 40px 120px rgba(0,0,0,0.7), 0 0 60px ${index % 2 === 0 ? CYAN : ORANGE}12`,
            border: `1px solid ${index % 2 === 0 ? CYAN : ORANGE}20`,
          }}
        />
      )}

      {/* Bottom-left badge (hero only) */}
      {isHero && (
        <div
          style={{
            position: "absolute",
            bottom: 80,
            left: 160,
            display: "flex",
            gap: 16,
          }}
        >
          {["Free Forever", "100% Local", "macOS 14+"].map((t) => (
            <div
              key={t}
              style={{
                padding: "10px 24px",
                borderRadius: 100,
                background: `${BG_CARD}CC`,
                border: `1px solid ${TEXT_SECONDARY}20`,
                color: TEXT_SECONDARY,
                fontSize: 26,
                fontWeight: 500,
              }}
            >
              {t}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default function ScreenshotsPage() {
  const exportRefs = useRef<Map<string, HTMLDivElement>>(new Map());
  const [exporting, setExporting] = useState<string | null>(null);
  const [activeSet, setActiveSet] = useState(0);

  const currentSet = SLIDE_SETS[activeSet];
  const slides = currentSet.slides;

  const exportSlide = useCallback(
    async (setId: string, slideIndex: number, slide: Slide) => {
      const key = `${setId}-${slideIndex}`;
      const el = exportRefs.current.get(key);
      if (!el) return;

      setExporting(key);
      const wrapper = el.parentElement!;
      wrapper.style.left = "0px";
      wrapper.style.opacity = "1";
      wrapper.style.zIndex = "-1";

      try {
        const opts = { width: W, height: H, pixelRatio: 1, cacheBust: true };
        await toPng(el, opts);
        const dataUrl = await toPng(el, opts);

        const link = document.createElement("a");
        link.download = `${setId}-${String(slideIndex + 1).padStart(2, "0")}-${slide.id}-${W}x${H}.png`;
        link.href = dataUrl;
        link.click();
      } finally {
        wrapper.style.left = "-9999px";
        wrapper.style.opacity = "";
        wrapper.style.zIndex = "";
        setExporting(null);
      }
    },
    []
  );

  const exportCurrentSet = useCallback(async () => {
    for (let i = 0; i < slides.length; i++) {
      await exportSlide(currentSet.id, i, slides[i]);
      await new Promise((r) => setTimeout(r, 400));
    }
  }, [currentSet, slides, exportSlide]);

  const exportAllSets = useCallback(async () => {
    for (const set of SLIDE_SETS) {
      for (let i = 0; i < set.slides.length; i++) {
        await exportSlide(set.id, i, set.slides[i]);
        await new Promise((r) => setTimeout(r, 400));
      }
    }
  }, [exportSlide]);

  return (
    <div style={{ background: "#111", minHeight: "100vh", padding: 40 }}>
      <div style={{ maxWidth: 1600, margin: "0 auto" }}>
        {/* Header */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
          <div>
            <h1 style={{ color: TEXT_PRIMARY, fontSize: 32, fontWeight: 700, margin: 0 }}>ClipSlim Screenshots</h1>
            <p style={{ color: TEXT_SECONDARY, fontSize: 16, margin: "8px 0 0" }}>
              {W} x {H} — Mac App Store (Retina)
            </p>
          </div>
          <div style={{ display: "flex", gap: 12 }}>
            <button
              onClick={exportCurrentSet}
              style={{
                background: "transparent",
                border: `1px solid ${CYAN}`,
                color: CYAN,
                padding: "12px 24px",
                borderRadius: 12,
                fontSize: 14,
                fontWeight: 600,
                cursor: "pointer",
              }}
            >
              Export {currentSet.name}
            </button>
            <button
              onClick={exportAllSets}
              style={{
                background: CYAN,
                color: "#000",
                border: "none",
                padding: "12px 32px",
                borderRadius: 12,
                fontSize: 14,
                fontWeight: 700,
                cursor: "pointer",
              }}
            >
              Export All Sets
            </button>
          </div>
        </div>

        {/* Set tabs */}
        <div style={{ display: "flex", gap: 8, marginBottom: 32 }}>
          {SLIDE_SETS.map((set, i) => (
            <button
              key={set.id}
              onClick={() => setActiveSet(i)}
              style={{
                padding: "10px 24px",
                borderRadius: 10,
                border: activeSet === i ? `2px solid ${CYAN}` : "1px solid #333",
                background: activeSet === i ? `${CYAN}12` : "transparent",
                color: activeSet === i ? CYAN : TEXT_SECONDARY,
                fontSize: 14,
                fontWeight: 600,
                cursor: "pointer",
              }}
            >
              {set.name}
              <span style={{ fontSize: 11, opacity: 0.6, marginLeft: 8 }}>
                {set.slides.length} slides
              </span>
            </button>
          ))}
        </div>

        {/* Set description & promo text */}
        <div style={{ marginBottom: 24, padding: "16px 20px", borderRadius: 12, background: BG_CARD, border: "1px solid #222" }}>
          <div style={{ color: TEXT_SECONDARY, fontSize: 13, marginBottom: 8 }}>{currentSet.description}</div>
          <div style={{ color: ORANGE, fontSize: 13, fontStyle: "italic" }}>Promo: {currentSet.promoText}</div>
        </div>

        {/* Preview grid */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: 24 }}>
          {slides.map((slide, i) => (
            <PreviewCard
              key={slide.id}
              slide={slide}
              index={i}
              totalSlides={slides.length}
              exporting={exporting === `${currentSet.id}-${i}`}
              onExport={() => exportSlide(currentSet.id, i, slide)}
            />
          ))}
        </div>

        {/* Offscreen export targets for ALL sets */}
        {SLIDE_SETS.map((set) =>
          set.slides.map((slide, i) => (
            <div
              key={`export-${set.id}-${slide.id}`}
              style={{
                position: "absolute",
                left: -9999,
                fontFamily: "Inter, system-ui, -apple-system, sans-serif",
              }}
              ref={(el) => {
                if (el?.firstElementChild) {
                  exportRefs.current.set(`${set.id}-${i}`, el.firstElementChild as HTMLDivElement);
                }
              }}
            >
              <SlideContent slide={slide} index={i} totalSlides={set.slides.length} />
            </div>
          ))
        )}
      </div>
    </div>
  );
}

function PreviewCard({
  slide,
  index,
  totalSlides,
  exporting,
  onExport,
}: {
  slide: Slide;
  index: number;
  totalSlides: number;
  exporting: boolean;
  onExport: () => void;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(0.25);

  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const obs = new ResizeObserver(([entry]) => {
      const w = entry.contentRect.width;
      setScale(w / W);
    });
    obs.observe(el);
    return () => obs.disconnect();
  }, []);

  return (
    <div>
      <div
        ref={containerRef}
        style={{
          width: "100%",
          aspectRatio: `${W}/${H}`,
          overflow: "hidden",
          borderRadius: 12,
          border: "1px solid #333",
          position: "relative",
          cursor: "pointer",
        }}
        onClick={onExport}
      >
        <div style={{ transform: `scale(${scale})`, transformOrigin: "top left" }}>
          <SlideContent slide={slide} index={index} totalSlides={totalSlides} />
        </div>

        {exporting && (
          <div
            style={{
              position: "absolute",
              inset: 0,
              background: "rgba(0,0,0,0.7)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: CYAN,
              fontSize: 20,
              fontWeight: 600,
            }}
          >
            Exporting...
          </div>
        )}
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 8 }}>
        <span style={{ color: TEXT_SECONDARY, fontSize: 14 }}>
          {String(index + 1).padStart(2, "0")} — {slide.label}
        </span>
        <button
          onClick={onExport}
          style={{
            background: "transparent",
            border: "1px solid #444",
            color: TEXT_PRIMARY,
            padding: "6px 16px",
            borderRadius: 8,
            fontSize: 13,
            cursor: "pointer",
          }}
        >
          Export PNG
        </button>
      </div>
    </div>
  );
}
