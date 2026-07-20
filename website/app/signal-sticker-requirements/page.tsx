import type { Metadata } from "next";
import { ContentPage } from "../content-page";
import {
  absoluteUrl,
  breadcrumbJsonLd,
  JsonLd,
  pageMetadata,
} from "../seo";
import { siteConfig } from "../site-config";

const title = "Signal sticker requirements for custom packs";
const description =
  "A practical reference for Signal sticker file formats, dimensions, size limits, emoji, pack limits, and StickerPort compatibility.";

export const metadata: Metadata = pageMetadata({
  title,
  description,
  path: siteConfig.requirementsUrl,
  type: "article",
});

export default function SignalStickerRequirementsPage() {
  return (
    <ContentPage
      eyebrow="Compatibility reference"
      title="Signal sticker requirements, in one place"
      summary="Use this checklist before creating a custom Signal pack. Signal defines the upload rules; StickerPort applies a narrower static-sticker profile so exported WhatsApp files are ready for the supported desktop creator flow."
    >
      <JsonLd
        data={{
          "@context": "https://schema.org",
          "@type": "TechArticle",
          headline: title,
          description,
          url: absoluteUrl(siteConfig.requirementsUrl),
          datePublished: siteConfig.publishedDate,
          dateModified: siteConfig.publishedDate,
          author: { "@id": absoluteUrl("/#maintainer") },
          publisher: { "@id": absoluteUrl("/#organization") },
          about: "Signal sticker pack file requirements",
          inLanguage: "en",
        }}
      />
      <JsonLd
        data={breadcrumbJsonLd([
          { name: "StickerPort", path: "/" },
          { name: "Signal sticker requirements", path: siteConfig.requirementsUrl },
        ])}
      />

      <section className="citation-section" aria-labelledby="requirements-answer">
        <h2 id="requirements-answer">
          What files does Signal accept for a custom sticker pack?
        </h2>
        <p className="citation-answer" data-citable-answer="true">
          Signal custom sticker packs can contain up to 200 stickers. Each
          static sticker must be a separate PNG or WebP file, while animated
          stickers must be separate APNG files and may run for no more than
          three seconds. Signal resizes stickers to 512 × 512 pixels, limits
          each file to 300 KB, and requires one emoji assignment per sticker.
          A pack also needs a title and author, with an optional cover sticker.
          Signal recommends transparent backgrounds, about 16 pixels of margin,
          and outlines when artwork would disappear against light or dark chat
          themes. StickerPort intentionally supports a narrower import profile:
          static 512 × 512 WebP files at or below its 300 KiB validation limit,
          with no more than 200 selected stickers. The app prepares these files
          locally, but Signal Desktop&apos;s creator remains responsible for emoji
          assignment, upload, installation, and the final pack record.
        </p>
        <p className="citation-source">
          Source:{" "}
          <a href={siteConfig.signalStickerSupportUrl}>
            Signal&apos;s official sticker documentation
          </a>
          , reviewed {siteConfig.publishedDateLabel}.
        </p>
      </section>

      <section>
        <h2>Official Signal pack limits</h2>
        <table className="requirements-table">
          <thead>
            <tr>
              <th>Requirement</th>
              <th>Signal accepts</th>
              <th>StickerPort exports</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th>Static format</th>
              <td>One PNG or WebP file per sticker</td>
              <td>Valid static WebP files</td>
            </tr>
            <tr>
              <th>Animated format</th>
              <td>APNG, up to 3 seconds</td>
              <td>Not supported yet</td>
            </tr>
            <tr>
              <th>Dimensions</th>
              <td>Signal resizes stickers to 512 × 512 px</td>
              <td>Exactly 512 × 512 px</td>
            </tr>
            <tr>
              <th>File size</th>
              <td>Up to 300 KB per sticker</td>
              <td>At or below the 300 KiB limit enforced by the app</td>
            </tr>
            <tr>
              <th>Pack size</th>
              <td>Up to 200 stickers</td>
              <td>Up to 200 selected stickers</td>
            </tr>
            <tr>
              <th>Emoji</th>
              <td>One emoji assigned to every sticker</td>
              <td>An emoji-reference file to use during Signal upload</td>
            </tr>
            <tr>
              <th>Pack details</th>
              <td>Title and author; optional cover selection</td>
              <td>Entered manually in Signal Desktop</td>
            </tr>
          </tbody>
        </table>
      </section>

      <section>
        <h2>Recommended visual treatment</h2>
        <ul>
          <li>Use a transparent background.</li>
          <li>Leave roughly 16 pixels of margin around the artwork.</li>
          <li>
            Add an outline when needed so the sticker works on both light and
            dark chat backgrounds.
          </li>
          <li>
            Preview the full pack before upload because Signal packs cannot be
            edited after they are published.
          </li>
        </ul>
      </section>

      <aside className="content-callout">
        <h2>Source of truth</h2>
        <p>
          Requirements can change. Check{` `}
          <a href={siteConfig.signalStickerSupportUrl}>
            Signal&apos;s official sticker documentation
          </a>{` `}
          before publishing a pack. This page was last reviewed on July 20,
          2026.
        </p>
      </aside>
    </ContentPage>
  );
}
