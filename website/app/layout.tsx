import type { Metadata } from "next";
import { headers } from "next/headers";
import "./globals.css";
import { siteConfig } from "./site-config";

async function requestOrigin() {
  const requestHeaders = await headers();
  const host =
    requestHeaders.get("x-forwarded-host") ??
    requestHeaders.get("host") ??
    "localhost";
  const protocol =
    requestHeaders.get("x-forwarded-proto") ??
    (host.startsWith("localhost") ? "http" : "https");

  return `${protocol}://${host}`;
}

export async function generateMetadata(): Promise<Metadata> {
  const origin = await requestOrigin();

  return {
    title: siteConfig.title,
    description: siteConfig.description,
    applicationName: siteConfig.name,
    icons: {
      icon: "/stickerport-icon.png",
      shortcut: "/stickerport-icon.png",
      apple: "/stickerport-icon.png",
    },
    openGraph: {
      title: siteConfig.title,
      description: siteConfig.description,
      type: "website",
      url: origin,
      images: [
        {
          url: `${origin}/og.png`,
          width: 1200,
          height: 630,
          alt: "Bring your WhatsApp stickers to Signal with StickerPort.",
        },
      ],
    },
    twitter: {
      card: "summary_large_image",
      title: siteConfig.title,
      description: siteConfig.description,
      images: [`${origin}/og.png`],
    },
  };
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
