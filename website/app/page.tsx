import Image from "next/image";
import { TrackedDownloadLink } from "./analytics";
import { siteConfig } from "./site-config";

const stickers = [
  {
    src: "/stickers/cuppy-smile.webp",
    className: "sample-sticker sample-sticker--smile",
  },
  {
    src: "/stickers/cuppy-love.webp",
    className: "sample-sticker sample-sticker--love",
  },
  {
    src: "/stickers/cuppy-workhard.webp",
    className: "sample-sticker sample-sticker--work",
  },
  {
    src: "/stickers/cuppy-hi.webp",
    className: "sample-sticker sample-sticker--hi",
  },
] as const;

export default function Home() {
  return (
    <main className="landing-shell">
      <div className="stage-glow stage-glow--navy" aria-hidden="true" />
      <div className="stage-glow stage-glow--aqua" aria-hidden="true" />

      <article className="mac-window" id="top">
        <header className="window-toolbar">
          <div className="traffic-lights" aria-hidden="true">
            <span />
            <span />
            <span />
          </div>
          <a className="toolbar-brand" href="#top" aria-label="StickerPort home">
            <Image
              className="toolbar-icon"
              src="/stickerport-icon.png"
              alt=""
              width={32}
              height={32}
              priority
              unoptimized
            />
            <span>{siteConfig.name}</span>
          </a>
          <span className="toolbar-note">Private by design</span>
        </header>

        <div className="window-content">
          <section className="hero" aria-labelledby="hero-title">
            <div className="hero-card">
              <div className="product-lockup">
                <Image
                  className="hero-app-icon"
                  src="/stickerport-icon.png"
                  alt="StickerPort app icon"
                  width={128}
                  height={128}
                  priority
                  unoptimized
                />
                <div>
                  <p className="eyebrow">WhatsApp → Signal · On your Mac</p>
                  <p className="product-kicker">StickerPort for macOS</p>
                </div>
              </div>

              <h1 id="hero-title">{siteConfig.headline}</h1>
              <p className="lede">{siteConfig.supportingCopy}</p>

              <div className="actions">
                <TrackedDownloadLink
                  className="download-button"
                  href={siteConfig.downloadUrl}
                >
                  <span className="download-symbol" aria-hidden="true">
                    ↓
                  </span>
                  <span>Download for Mac</span>
                </TrackedDownloadLink>
                <p className="compatibility">{siteConfig.compatibility}</p>
              </div>

              <ul className="trust-list" aria-label="Privacy promises">
                <li className="trust-list__device">
                  <span aria-hidden="true">◆</span> On-device
                </li>
                <li className="trust-list__read">
                  <span aria-hidden="true">●</span> Read-only
                </li>
              </ul>
            </div>

            <figure
              className="sticker-shelf"
              aria-label="Real WhatsApp sample stickers prepared by StickerPort"
            >
              <div className="shelf-heading">
                <div>
                  <p>Sticker shelf</p>
                  <strong>Bring the ones you love.</strong>
                </div>
                <span>Your collection</span>
              </div>

              <div className="shelf-stage">
                <span className="platform-chip platform-chip--source">
                  WhatsApp
                </span>
                <div className="transfer-path" aria-hidden="true" />

                {stickers.map((sticker) => (
                  <Image
                    className={sticker.className}
                    src={sticker.src}
                    alt=""
                    width={256}
                    height={256}
                    key={sticker.src}
                    unoptimized
                  />
                ))}

                <div className="folder-card">
                  <span className="folder-card__tab" aria-hidden="true" />
                  <div className="folder-card__icon" aria-hidden="true">
                    <span />
                    <span />
                    <span />
                  </div>
                  <div>
                    <strong>Signal-ready</strong>
                    <span>Ordinary folder</span>
                  </div>
                  <span className="ready-dot" aria-hidden="true" />
                </div>

                <span className="platform-chip platform-chip--destination">
                  Signal
                </span>
              </div>
            </figure>
          </section>

          <footer className="site-footer">
            <span>Not affiliated with WhatsApp or Signal.</span>
            <div>
              <a href={siteConfig.repositoryUrl}>View app source</a>
            </div>
          </footer>
        </div>
      </article>
    </main>
  );
}
