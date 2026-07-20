import type { Metadata } from "next";
import { TrackedDownloadLink } from "../../analytics";
import { ContentPage } from "../../content-page";
import {
  absoluteUrl,
  breadcrumbJsonLd,
  JsonLd,
  pageMetadata,
} from "../../seo";
import { siteConfig } from "../../site-config";

const title = "How to transfer WhatsApp stickers to Signal on a Mac";
const description =
  "Move installed WhatsApp Desktop sticker packs and Favorites into Signal with a local, read-only macOS workflow.";

export const metadata: Metadata = pageMetadata({
  title,
  description,
  path: siteConfig.guideUrl,
  type: "article",
});

const guideSteps = [
  {
    name: "Install the desktop apps",
    text: "Install WhatsApp Desktop, Signal Desktop, and StickerPort on a Mac running macOS 15 or later.",
  },
  {
    name: "Quit WhatsApp completely",
    text: "Choose WhatsApp → Quit WhatsApp so its sticker databases are not changing while StickerPort reads them.",
  },
  {
    name: "Choose WhatsApp's shared folder",
    text: "Open StickerPort and use the macOS folder picker to choose group.net.whatsapp.WhatsApp.shared when asked.",
  },
  {
    name: "Select packs or Favorites",
    text: "Choose up to 200 supported static stickers from the packs and Favorites found on your Mac.",
  },
  {
    name: "Export a Signal-ready folder",
    text: "Pick an output location. StickerPort validates the files and creates a numbered Stickers folder plus an emoji reference and handoff guide.",
  },
  {
    name: "Open Signal's sticker creator",
    text: "In Signal Desktop, choose File → Create/Upload Sticker Pack and select every exported sticker.",
  },
  {
    name: "Add emoji and install",
    text: "Assign one emoji per sticker, add the pack title and author, confirm the upload, then install the pack in Signal Desktop.",
  },
] as const;

const guideSchema = {
  "@context": "https://schema.org",
  "@type": "HowTo",
  name: title,
  description,
  url: absoluteUrl(siteConfig.guideUrl),
  datePublished: siteConfig.publishedDate,
  dateModified: siteConfig.publishedDate,
  author: { "@id": absoluteUrl("/#maintainer") },
  publisher: { "@id": absoluteUrl("/#organization") },
  tool: [
    { "@type": "HowToTool", name: "A Mac running macOS 15 or later" },
    { "@type": "HowToTool", name: "WhatsApp Desktop" },
    { "@type": "HowToTool", name: "Signal Desktop" },
    { "@type": "HowToTool", name: "StickerPort" },
  ],
  step: guideSteps.map((step, index) => ({
    "@type": "HowToStep",
    position: index + 1,
    name: step.name,
    text: step.text,
    url: `${absoluteUrl(siteConfig.guideUrl)}#step-${index + 1}`,
  })),
};

export default function TransferGuidePage() {
  return (
    <ContentPage
      eyebrow="Step-by-step guide"
      title="Transfer WhatsApp stickers to Signal on your Mac"
      summary="StickerPort turns the stickers already stored by WhatsApp Desktop into files that Signal Desktop's official sticker creator can accept. The source is opened read-only and the final upload stays under your control."
    >
      <JsonLd data={guideSchema} />
      <JsonLd
        data={breadcrumbJsonLd([
          { name: "StickerPort", path: "/" },
          { name: "WhatsApp stickers to Signal", path: siteConfig.guideUrl },
        ])}
      />

      <section className="citation-section" aria-labelledby="transfer-answer">
        <h2 id="transfer-answer">
          How do you transfer WhatsApp stickers to Signal on a Mac?
        </h2>
        <p className="citation-answer" data-citable-answer="true">
          To transfer WhatsApp stickers to Signal on a Mac, quit WhatsApp
          Desktop, open StickerPort, and choose the shared WhatsApp folder when
          macOS asks. StickerPort reads the supported sticker catalog and files
          locally, opens its SQLite sources read-only, and lets you select
          installed packs or Favorites. It then validates up to 200 static WebP
          stickers, each 512 × 512 pixels and no larger than the app&apos;s 300
          KiB limit, before creating an ordinary export folder. Nothing is
          uploaded during this step, WhatsApp data is not changed, and
          StickerPort does not write to Signal&apos;s private storage. Finish in
          Signal Desktop by choosing File → Create/Upload Sticker Pack,
          selecting the exported files, assigning one emoji to each sticker,
          and adding a title and author. Signal&apos;s own creator performs the
          upload and installation, so you retain control of the final published
          pack.
        </p>
        <p className="citation-source">
          Sources:{" "}
          <a href={siteConfig.signalStickerSupportUrl}>
            Signal&apos;s official sticker guide
          </a>{" "}
          and the <a href={siteConfig.repositoryUrl}>StickerPort source</a>.
        </p>
      </section>

      <aside className="content-callout">
        <h2>What this workflow does</h2>
        <p>
          StickerPort does not sign in to WhatsApp, upload a Signal pack, or
          write into either app&apos;s private storage. It reads the folder you
          explicitly select, exports compatible files, and then hands the work
          to Signal Desktop&apos;s supported creator flow.
        </p>
      </aside>

      <section>
        <h2>The complete transfer workflow</h2>
        <ol className="content-steps">
          {guideSteps.map((step, index) => (
            <li id={`step-${index + 1}`} key={step.name}>
              <h3>{step.name}</h3>
              <p>{step.text}</p>
            </li>
          ))}
        </ol>
      </section>

      <section>
        <h2>Why WhatsApp must be closed first</h2>
        <p>
          WhatsApp can update its SQLite databases and write-ahead logs while
          it is running. StickerPort fails closed if the source looks active or
          changes during the read, which avoids exporting a half-updated pack.
          Use WhatsApp → Quit WhatsApp rather than only closing its window.
        </p>
      </section>

      <section>
        <h2>Common problems</h2>
        <div className="content-grid">
          <div>
            <h3>No packs appear</h3>
            <p>
              Confirm that you selected the shared WhatsApp container and that
              the installed WhatsApp schema is still supported.
            </p>
          </div>
          <div>
            <h3>A sticker is skipped</h3>
            <p>
              StickerPort currently accepts static 512 × 512 WebP files at or
              below Signal&apos;s 300 KiB limit. Animated stickers are not yet
              supported.
            </p>
          </div>
          <div>
            <h3>Signal will not accept the pack</h3>
            <p>
              Keep the pack at 200 stickers or fewer and select the individual
              exported files, not the parent folder itself.
            </p>
          </div>
          <div>
            <h3>You expected automatic installation</h3>
            <p>
              StickerPort intentionally stops at a normal folder. Signal
              Desktop performs the upload and installation through its own
              creator.
            </p>
          </div>
        </div>
      </section>

      <section>
        <h2>Signal&apos;s official final step</h2>
        <p>
          Signal documents its sticker creator, supported formats, size limits,
          emoji assignment, and installation flow in the official{` `}
          <a href={siteConfig.signalStickerSupportUrl}>Signal sticker guide</a>.
          StickerPort prepares the local files; Signal remains the authority
          for upload and pack behavior.
        </p>
      </section>

      <aside className="content-cta">
        <h2>Ready to move your stickers?</h2>
        <p>
          Download the current universal macOS release and keep the whole
          extraction step on your Mac.
        </p>
        <TrackedDownloadLink
          className="content-cta-link"
          href={siteConfig.downloadUrl}
          placement="transfer_guide"
        >
          Download StickerPort for Mac
        </TrackedDownloadLink>
      </aside>
    </ContentPage>
  );
}
