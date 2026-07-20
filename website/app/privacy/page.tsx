import type { Metadata } from "next";
import { ContentPage } from "../content-page";
import {
  absoluteUrl,
  breadcrumbJsonLd,
  JsonLd,
  pageMetadata,
} from "../seo";
import { siteConfig } from "../site-config";

const title = "StickerPort privacy and read-only design";
const description =
  "See exactly what StickerPort reads, writes, validates, and measures when moving WhatsApp stickers into a Signal-ready folder.";

export const metadata: Metadata = pageMetadata({
  title,
  description,
  path: siteConfig.privacyUrl,
});

export default function PrivacyPage() {
  return (
    <ContentPage
      eyebrow="Privacy by design"
      title="Your stickers stay on your Mac"
      summary="StickerPort is built around explicit folder access, read-only database handling, local validation, and an ordinary export folder. It does not need your chat credentials and does not automate Signal's private interfaces."
    >
      <JsonLd
        data={{
          "@context": "https://schema.org",
          "@type": "WebPage",
          name: title,
          description,
          url: absoluteUrl(siteConfig.privacyUrl),
          isPartOf: { "@id": absoluteUrl("/#website") },
          about: { "@id": absoluteUrl("/#software") },
          datePublished: siteConfig.publishedDate,
          dateModified: siteConfig.publishedDate,
          author: { "@id": absoluteUrl("/#maintainer") },
          publisher: { "@id": absoluteUrl("/#organization") },
        }}
      />
      <JsonLd
        data={breadcrumbJsonLd([
          { name: "StickerPort", path: "/" },
          { name: "Privacy", path: siteConfig.privacyUrl },
        ])}
      />

      <section className="citation-section" aria-labelledby="privacy-answer">
        <h2 id="privacy-answer">
          Does StickerPort upload or change your WhatsApp stickers?
        </h2>
        <p className="citation-answer" data-citable-answer="true">
          StickerPort is a local-only macOS utility: it does not upload your
          WhatsApp sticker collection, sign in to either messaging service, or
          write into WhatsApp or Signal&apos;s private storage. You explicitly
          choose WhatsApp Desktop&apos;s shared container with the macOS folder
          picker. The importer opens supported SQLite databases read-only,
          enables query-only mode, and rejects active write-ahead logs,
          unexpected schemas, unsafe paths, escaping symlinks, or a source that
          changes during the read. StickerPort writes only to the destination
          folder you select, producing numbered sticker files, an emoji
          reference, and a handoff guide. You then decide whether to upload
          those files through Signal Desktop&apos;s official sticker creator. The
          website may measure page views and download clicks when its Mixpanel
          token is configured, but autocapture, session recording, persistent
          visitor storage, IP geolocation, full referrer URLs, and query strings
          are disabled.
        </p>
        <p className="citation-source">
          Evidence: <a href={siteConfig.repositoryUrl}>public source code</a>,
          tests, and release verification scripts.
        </p>
      </section>

      <section>
        <h2>What the Mac app reads</h2>
        <ul>
          <li>
            Only the WhatsApp Desktop shared container that you explicitly
            choose in the macOS folder picker.
          </li>
          <li>
            Known sticker catalog records and sticker files required to show
            installed packs and Favorites.
          </li>
          <li>
            Source databases opened with SQLite read-only and query-only modes.
          </li>
        </ul>
      </section>

      <section>
        <h2>What the Mac app writes</h2>
        <p>
          StickerPort writes only to the destination folder you choose. The
          export contains numbered sticker files, an emoji reference, and a
          short handoff guide. It does not modify WhatsApp data or write into
          Signal&apos;s private application storage.
        </p>
      </section>

      <section>
        <h2>Safety checks before export</h2>
        <div className="content-grid">
          <div>
            <h3>Inactive source</h3>
            <p>
              The app rejects active write-ahead logs and asks you to quit
              WhatsApp before reading.
            </p>
          </div>
          <div>
            <h3>Expected schema</h3>
            <p>
              Unknown database layouts fail closed instead of being guessed at.
            </p>
          </div>
          <div>
            <h3>Safe paths</h3>
            <p>
              Unsafe paths and symlinks that escape the selected container are
              rejected.
            </p>
          </div>
          <div>
            <h3>Stable snapshot</h3>
            <p>
              StickerPort checks that the source did not change while it was
              being read.
            </p>
          </div>
        </div>
      </section>

      <section>
        <h2>Website measurement</h2>
        <p>
          When the site&apos;s Mixpanel project token is configured, the website
          records page views and download clicks. Autocapture, session
          recording, persistent visitor storage, and IP geolocation are
          disabled. Referrer reporting is reduced to the referring hostname;
          full referring URLs and query strings are not sent.
        </p>
      </section>

      <aside className="content-callout">
        <h2>Inspect the implementation</h2>
        <p>
          StickerPort is open source. Review the{` `}
          <a href={siteConfig.repositoryUrl}>source repository</a>, release
          history, and verification scripts before running it.
        </p>
      </aside>
    </ContentPage>
  );
}
