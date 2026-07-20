import type { Metadata } from "next";
import { ContentPage } from "../content-page";
import {
  absoluteUrl,
  breadcrumbJsonLd,
  JsonLd,
  pageMetadata,
} from "../seo";
import { siteConfig } from "../site-config";

const title = "StickerPort FAQ";
const description =
  "Answers about WhatsApp folder access, Signal uploads, privacy, supported stickers, macOS compatibility, and StickerPort releases.";

export const metadata: Metadata = pageMetadata({
  title,
  description,
  path: siteConfig.faqUrl,
});

const faqs = [
  {
    question: "Does StickerPort upload my stickers?",
    answer:
      "No. StickerPort creates an ordinary folder on your Mac. You choose whether to upload those files with Signal Desktop's official sticker creator.",
  },
  {
    question: "Does StickerPort change WhatsApp data?",
    answer:
      "No. The importer opens the supported WhatsApp sticker databases read-only and uses query-only mode. It writes only to the export folder you choose.",
  },
  {
    question: "Does StickerPort need Full Disk Access?",
    answer:
      "No. macOS asks you to choose WhatsApp's shared container explicitly. StickerPort uses that user-granted folder access rather than requesting broad disk access.",
  },
  {
    question: "Why must WhatsApp be quit?",
    answer:
      "WhatsApp can change its databases while running. StickerPort rejects active or changing sources so it does not export an inconsistent snapshot.",
  },
  {
    question: "Are animated stickers supported?",
    answer:
      "Not yet. The current release exports supported static WebP stickers. Signal itself supports APNG for animated stickers, but StickerPort's importer does not export them today.",
  },
  {
    question: "How many stickers can I move at once?",
    answer:
      "Up to 200, matching Signal's maximum number of stickers in a custom pack.",
  },
  {
    question: "Which Macs are supported?",
    answer:
      "StickerPort requires macOS 15 or later. The current DMG is a universal build for Apple silicon and Intel Macs.",
  },
  {
    question: "Is StickerPort affiliated with WhatsApp or Signal?",
    answer:
      "No. StickerPort is an independent open-source utility. WhatsApp and Signal remain responsible for their own apps, formats, and policies.",
  },
] as const;

export default function FaqPage() {
  return (
    <ContentPage
      eyebrow="Questions and answers"
      title="StickerPort FAQ"
      summary="The short version: StickerPort reads the WhatsApp sticker data you select, creates a local Signal-ready folder, and leaves the final upload to you and Signal Desktop."
    >
      <JsonLd
        data={{
          "@context": "https://schema.org",
          "@type": "FAQPage",
          url: absoluteUrl(siteConfig.faqUrl),
          datePublished: siteConfig.publishedDate,
          dateModified: siteConfig.publishedDate,
          author: { "@id": absoluteUrl("/#maintainer") },
          publisher: { "@id": absoluteUrl("/#organization") },
          mainEntity: faqs.map((faq) => ({
            "@type": "Question",
            name: faq.question,
            acceptedAnswer: {
              "@type": "Answer",
              text: faq.answer,
            },
          })),
        }}
      />
      <JsonLd
        data={breadcrumbJsonLd([
          { name: "StickerPort", path: "/" },
          { name: "FAQ", path: siteConfig.faqUrl },
        ])}
      />

      <section>
        <div className="faq-list">
          {faqs.map((faq) => (
            <div key={faq.question}>
              <h2>{faq.question}</h2>
              <p>{faq.answer}</p>
            </div>
          ))}
        </div>
      </section>

      <aside className="content-callout">
        <h2>Still deciding?</h2>
        <p>
          Read the detailed{` `}
          <a href={siteConfig.guideUrl}>WhatsApp-to-Signal transfer guide</a>,
          review the <a href={siteConfig.privacyUrl}>privacy model</a>, or
          inspect the <a href={siteConfig.repositoryUrl}>source code</a>.
        </p>
      </aside>
    </ContentPage>
  );
}
