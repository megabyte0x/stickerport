import type { Metadata } from "next";
import "./globals.css";
import { Analytics } from "./analytics";
import { absoluteUrl, JsonLd } from "./seo";
import { siteConfig } from "./site-config";

const googleSiteVerification =
  process.env.NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION?.trim();
const bingSiteVerification =
  process.env.NEXT_PUBLIC_BING_SITE_VERIFICATION?.trim();

export const metadata: Metadata = {
  metadataBase: new URL(siteConfig.url),
  title: siteConfig.title,
  description: siteConfig.description,
  applicationName: siteConfig.name,
  alternates: {
    canonical: siteConfig.url,
  },
  icons: {
    icon: "/stickerport-icon.png",
    shortcut: "/stickerport-icon.png",
    apple: "/stickerport-icon.png",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-image-preview": "large",
      "max-snippet": -1,
      "max-video-preview": -1,
    },
  },
  ...(googleSiteVerification || bingSiteVerification
    ? {
        verification: {
          ...(googleSiteVerification
            ? { google: googleSiteVerification }
            : {}),
          ...(bingSiteVerification
            ? { other: { "msvalidate.01": bingSiteVerification } }
            : {}),
        },
      }
    : {}),
  openGraph: {
    title: siteConfig.title,
    description: siteConfig.description,
    type: "website",
    url: siteConfig.url,
    siteName: siteConfig.name,
    images: [
      {
        url: absoluteUrl("/og.png"),
        width: 1200,
        height: 630,
        type: "image/png",
        alt: "Bring your WhatsApp stickers to Signal with StickerPort.",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: siteConfig.title,
    description: siteConfig.description,
    images: [
      {
        url: absoluteUrl("/og.png"),
        width: 1200,
        height: 630,
        type: "image/png",
        alt: "Bring your WhatsApp stickers to Signal with StickerPort.",
      },
    ],
  },
};

const siteSchema = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": absoluteUrl("/#organization"),
      name: siteConfig.name,
      url: siteConfig.url,
      logo: absoluteUrl("/stickerport-icon.png"),
      sameAs: [siteConfig.repositoryUrl],
      founder: { "@id": absoluteUrl("/#maintainer") },
    },
    {
      "@type": "Person",
      "@id": absoluteUrl("/#maintainer"),
      name: siteConfig.maintainerName,
      url: siteConfig.maintainerUrl,
      sameAs: [siteConfig.maintainerUrl],
      knowsAbout: [
        "macOS application development",
        "read-only SQLite import workflows",
        "WhatsApp Desktop stickers",
        "Signal Desktop sticker packs",
      ],
    },
    {
      "@type": "WebSite",
      "@id": absoluteUrl("/#website"),
      name: siteConfig.name,
      url: siteConfig.url,
      description: siteConfig.description,
      publisher: { "@id": absoluteUrl("/#organization") },
      inLanguage: "en",
    },
    {
      "@type": "SoftwareApplication",
      "@id": absoluteUrl("/#software"),
      name: siteConfig.name,
      description: siteConfig.description,
      url: siteConfig.url,
      downloadUrl: absoluteUrl(siteConfig.downloadUrl),
      softwareVersion: siteConfig.version,
      operatingSystem: siteConfig.compatibility,
      applicationCategory: "UtilitiesApplication",
      isAccessibleForFree: true,
      author: { "@id": absoluteUrl("/#maintainer") },
      publisher: { "@id": absoluteUrl("/#organization") },
      offers: {
        "@type": "Offer",
        price: "0",
        priceCurrency: "USD",
        availability: "https://schema.org/InStock",
      },
      featureList: [
        "Reads explicitly selected WhatsApp Desktop sticker data locally",
        "Opens the source databases read-only",
        "Exports static WebP stickers into a Signal-ready folder",
        "Uses Signal Desktop's official sticker creator for the final upload",
      ],
    },
  ],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>
        <JsonLd data={siteSchema} />
        {children}
        <Analytics />
      </body>
    </html>
  );
}
