import Image from "next/image";
import { siteConfig } from "./site-config";

const stickers = [
  { emoji: "😂", className: "sticker sticker--laugh" },
  { emoji: "🫶", className: "sticker sticker--love" },
  { emoji: "😎", className: "sticker sticker--cool" },
] as const;

export default function Home() {
  return (
    <main className="landing-shell">
      <div className="ambient ambient--green" aria-hidden="true" />
      <div className="ambient ambient--blue" aria-hidden="true" />

      <header className="site-header" aria-label="StickerPort">
        <a className="brand" href="#top" aria-label="StickerPort home">
          <Image
            className="brand-icon"
            src="/stickerport-icon.png"
            alt=""
            width={44}
            height={44}
            priority
            unoptimized
          />
          <span className="brand-name">{siteConfig.name}</span>
        </a>
        <span className="brand-note">Private by design · Made for Mac</span>
      </header>

      <section className="hero" id="top" aria-labelledby="hero-title">
        <div className="hero-copy">
          <p className="eyebrow">WhatsApp → Signal. On your Mac.</p>
          <h1 id="hero-title">{siteConfig.headline}</h1>
          <p className="lede">{siteConfig.supportingCopy}</p>

          <div className="actions">
            <a
              className="download-button"
              href={siteConfig.downloadUrl}
              download={`StickerPort-${siteConfig.version}.dmg`}
              aria-label={`Download StickerPort ${siteConfig.version} DMG for macOS`}
            >
              <span className="download-symbol" aria-hidden="true">
                ↓
              </span>
              <span>Download for Mac</span>
            </a>
            <p className="compatibility">{siteConfig.compatibility}</p>
          </div>

          <ul className="trust-list" aria-label="Privacy promises">
            <li>Read-only</li>
            <li>Local-only</li>
            <li>No account</li>
          </ul>
        </div>

        <figure
          className="handoff"
          aria-label="StickerPort prepares WhatsApp stickers for Signal"
        >
          <span className="platform platform--whatsapp">WhatsApp</span>
          <div className="handoff-line" aria-hidden="true" />

          {stickers.map((sticker) => (
            <span
              className={sticker.className}
              aria-hidden="true"
              key={sticker.emoji}
            >
              {sticker.emoji}
            </span>
          ))}

          <div className="app-card">
            <Image
              className="app-card-icon"
              src="/stickerport-icon.png"
              alt="StickerPort app icon"
              width={112}
              height={112}
              priority
              unoptimized
            />
            <div>
              <strong>StickerPort</strong>
              <span>Signal-ready folder</span>
            </div>
            <span className="ready-dot" aria-hidden="true" />
          </div>

          <span className="platform platform--signal">Signal</span>
        </figure>
      </section>

      <footer className="site-footer">
        <span>Not affiliated with WhatsApp or Signal.</span>
        <a href={siteConfig.repositoryUrl}>View source</a>
      </footer>
    </main>
  );
}
