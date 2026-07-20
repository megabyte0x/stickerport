import Image from "next/image";
import { TrackedDownloadLink } from "./analytics";
import { SignalTutorialVideo } from "./signal-tutorial-video";
import { siteConfig } from "./site-config";

const stickerPortSteps = [
  {
    title: "Quit WhatsApp",
    detail: "Use WhatsApp → Quit WhatsApp.",
  },
  {
    title: "Allow folder access",
    detail: "Choose WhatsApp’s shared folder when asked.",
  },
  {
    title: "Pick your stickers",
    detail: "Select packs or Favorites, up to 200.",
  },
  {
    title: "Create the Signal folder",
    detail: "Choose where StickerPort should save it.",
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

            <aside className="handoff-guide" aria-label="How to move stickers into Signal">
              <section className="guide-phase" aria-labelledby="stickerport-steps-title">
                <div className="requirements-strip">
                  <p>Requirements</p>
                  <ul aria-label="Required desktop apps">
                    <li>
                      <span className="requirement-mark requirement-mark--whatsapp" aria-hidden="true">
                        W
                      </span>
                      WhatsApp Desktop
                    </li>
                    <li>
                      <span className="requirement-mark requirement-mark--signal" aria-hidden="true">
                        S
                      </span>
                      Signal Desktop
                    </li>
                  </ul>
                </div>

                <header className="phase-heading">
                  <span className="phase-number" aria-hidden="true">1</span>
                  <div>
                    <p>First, in StickerPort</p>
                    <h2 id="stickerport-steps-title">Prepare your sticker folder</h2>
                  </div>
                </header>

                <ol className="stickerport-steps">
                  {stickerPortSteps.map((step, index) => (
                    <li key={step.title}>
                      <span className="step-number" aria-hidden="true">
                        {index + 1}
                      </span>
                      <span>
                        <strong>{step.title}</strong>
                        <small>{step.detail}</small>
                      </span>
                    </li>
                  ))}
                </ol>
              </section>

              <div className="handoff-divider" aria-hidden="true">
                <span>StickerPort opens the folder in Finder</span>
                <svg viewBox="0 0 24 24" role="presentation">
                  <path d="M5 12h13M14 7l5 5-5 5" />
                </svg>
              </div>

              <section className="guide-phase guide-phase--signal" aria-labelledby="signal-steps-title">
                <header className="phase-heading">
                  <span className="phase-number phase-number--signal" aria-hidden="true">2</span>
                  <div>
                    <p>Then, in Signal</p>
                    <h2 id="signal-steps-title">Upload and install the pack</h2>
                  </div>
                </header>

                <figure className="tutorial-frame">
                  <SignalTutorialVideo />
                  <figcaption>
                    Open creator <span aria-hidden="true">→</span> Select all
                    <span aria-hidden="true">→</span> Add details
                    <span aria-hidden="true">→</span> Upload &amp; install
                  </figcaption>
                </figure>
              </section>
            </aside>
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
