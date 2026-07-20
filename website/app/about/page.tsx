import type { Metadata } from "next";
import { ContentPage } from "../content-page";
import {
  absoluteUrl,
  breadcrumbJsonLd,
  JsonLd,
  pageMetadata,
} from "../seo";
import { siteConfig } from "../site-config";

const title = "About StickerPort";
const description =
  "StickerPort is an open-source macOS utility for locally preparing WhatsApp Desktop stickers for Signal Desktop.";

export const metadata: Metadata = pageMetadata({
  title,
  description,
  path: siteConfig.aboutUrl,
});

export default function AboutPage() {
  return (
    <ContentPage
      eyebrow="About the project"
      title="A small bridge between two desktop apps"
      summary="StickerPort exists to make one awkward migration task understandable and verifiable: finding the WhatsApp stickers already on a Mac and preparing them for Signal without automating private interfaces."
    >
      <JsonLd
        data={{
          "@context": "https://schema.org",
          "@type": "AboutPage",
          name: title,
          description,
          url: absoluteUrl(siteConfig.aboutUrl),
          datePublished: siteConfig.publishedDate,
          dateModified: siteConfig.publishedDate,
          author: { "@id": absoluteUrl("/#maintainer") },
          publisher: { "@id": absoluteUrl("/#organization") },
          mainEntity: { "@id": absoluteUrl("/#software") },
        }}
      />
      <JsonLd
        data={breadcrumbJsonLd([
          { name: "StickerPort", path: "/" },
          { name: "About", path: siteConfig.aboutUrl },
        ])}
      />

      <section>
        <h2>Why StickerPort exists</h2>
        <p>
          People moving conversations from WhatsApp to Signal often discover
          that their personal sticker collection does not move with them.
          Manual guides usually involve finding individual files, converting
          them, and rebuilding a pack. StickerPort narrows that work to a local
          selection and export flow on macOS.
        </p>
      </section>

      <section>
        <h2>Project principles</h2>
        <div className="content-grid">
          <div>
            <h3>Local first</h3>
            <p>Sticker extraction and validation happen on the Mac.</p>
          </div>
          <div>
            <h3>Read only</h3>
            <p>WhatsApp data is treated as a source, never a place to write.</p>
          </div>
          <div>
            <h3>Supported handoff</h3>
            <p>Signal Desktop&apos;s official creator performs the final upload.</p>
          </div>
          <div>
            <h3>Inspectable releases</h3>
            <p>Source, release notes, DMGs, and checksums are published openly.</p>
          </div>
        </div>
      </section>

      <section>
        <h2>Maintainer and evidence</h2>
        <p>
          StickerPort is built and maintained by{` `}
          <a href={siteConfig.maintainerUrl}>{siteConfig.maintainerName}</a>.
          The current release is {siteConfig.version}; its versioned artifacts,
          checksum, source history, and release workflow are available through
          the <a href={siteConfig.releaseUrl}>public release page</a>.
        </p>
      </section>

      <aside className="content-callout">
        <h2>Independent project</h2>
        <p>
          StickerPort is not affiliated with, endorsed by, or sponsored by
          WhatsApp or Signal. Product names are used only to describe the apps
          involved in the transfer workflow.
        </p>
      </aside>
    </ContentPage>
  );
}
