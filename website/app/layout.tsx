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
    },
    twitter: {
      card: "summary_large_image",
      title: siteConfig.title,
      description: siteConfig.description,
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
