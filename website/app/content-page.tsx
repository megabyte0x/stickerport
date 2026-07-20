import Image from "next/image";
import Link from "next/link";
import type { ReactNode } from "react";
import { siteConfig } from "./site-config";

const navigation = [
  { href: siteConfig.guideUrl, label: "Transfer guide" },
  { href: siteConfig.requirementsUrl, label: "Requirements" },
  { href: siteConfig.privacyUrl, label: "Privacy" },
  { href: siteConfig.faqUrl, label: "FAQ" },
] as const;

export function ContentPage({
  eyebrow,
  title,
  summary,
  children,
}: {
  eyebrow: string;
  title: string;
  summary: string;
  children: ReactNode;
}) {
  return (
    <main className="content-shell">
      <header className="content-header">
        <Link className="content-brand" href="/" aria-label="StickerPort home">
          <Image
            src="/stickerport-icon.png"
            alt=""
            width={38}
            height={38}
            unoptimized
          />
          <span>{siteConfig.name}</span>
        </Link>
        <nav className="content-nav" aria-label="StickerPort resources">
          {navigation.map((item) => (
            <Link href={item.href} key={item.href}>
              {item.label}
            </Link>
          ))}
        </nav>
        <Link
          className="content-download"
          href={siteConfig.downloadUrl}
          prefetch={false}
        >
          Download for Mac
        </Link>
      </header>

      <article className="content-article">
        <header className="content-hero">
          <p className="content-eyebrow">{eyebrow}</p>
          <h1>{title}</h1>
          <p className="content-summary">{summary}</p>
          <p className="content-byline">
            Maintained by{" "}
            <Link href={siteConfig.aboutUrl}>{siteConfig.maintainerName}</Link>
            {" · "}
            Reviewed{" "}
            <time dateTime={siteConfig.publishedDate}>
              {siteConfig.publishedDateLabel}
            </time>
          </p>
        </header>
        <div className="content-body">{children}</div>
      </article>

      <footer className="content-footer">
        <div>
          <strong>{siteConfig.name}</strong>
          <span>Local-only WhatsApp sticker export for Signal on macOS.</span>
        </div>
        <nav aria-label="Footer">
          <Link href={siteConfig.aboutUrl}>About</Link>
          <a href={siteConfig.repositoryUrl}>Source</a>
          <a href={siteConfig.releaseUrl}>Releases</a>
        </nav>
      </footer>
    </main>
  );
}
