"use client";

import mixpanel from "mixpanel-browser/src/loaders/loader-module-core";
import { usePathname } from "next/navigation";
import { useEffect, useRef, type ReactNode } from "react";

const projectToken = process.env.NEXT_PUBLIC_MIXPANEL_TOKEN?.trim();
const apiHost =
  process.env.NEXT_PUBLIC_MIXPANEL_API_HOST?.trim() ??
  "https://api.mixpanel.com";

let analyticsInitialized = false;

function pageType(path: string) {
  if (path === "/") return "landing";
  if (path.startsWith("/guides/")) return "guide";
  if (path === "/signal-sticker-requirements") return "reference";
  if (path === "/faq") return "faq";
  if (path === "/privacy") return "trust";
  if (path === "/about") return "company";
  return "other";
}

function trafficSource(referrer: string) {
  if (!referrer) return { traffic_source: "direct", referrer_host: "" };

  try {
    const host = new URL(referrer).hostname.toLowerCase();
    if (host === window.location.hostname.toLowerCase()) {
      return { traffic_source: "internal", referrer_host: host };
    }

    const organicSearchHosts = [
      "google.",
      "bing.com",
      "duckduckgo.com",
      "search.brave.com",
      "yahoo.",
      "ecosia.org",
      "perplexity.ai",
      "chatgpt.com",
    ];
    const organic = organicSearchHosts.some((candidate) =>
      host.includes(candidate),
    );
    return {
      traffic_source: organic ? "organic_search" : "referral",
      referrer_host: host,
    };
  } catch {
    return { traffic_source: "unknown", referrer_host: "" };
  }
}

function initializeAnalytics() {
  if (!projectToken) {
    return false;
  }

  if (!analyticsInitialized) {
    mixpanel.init(projectToken, {
      api_host: apiHost,
      autocapture: false,
      debug: process.env.NODE_ENV !== "production",
      disable_persistence: true,
      ignore_dnt: false,
      ip: false,
      record_sessions_percent: 0,
      stop_utm_persistence: true,
      track_pageview: false,
    });
    mixpanel.register({
      app: "StickerPort",
      surface: "website",
    });
    analyticsInitialized = true;
  }

  return true;
}

export function Analytics() {
  const pathname = usePathname();
  const lastTrackedPath = useRef<string | null>(null);

  useEffect(() => {
    if (
      !pathname ||
      lastTrackedPath.current === pathname ||
      !initializeAnalytics()
    ) {
      return;
    }

    mixpanel.track("Page Viewed", {
      page_path: pathname,
      page_type: pageType(pathname),
      ...trafficSource(document.referrer),
    });
    lastTrackedPath.current = pathname;
  }, [pathname]);

  return null;
}

export function TrackedDownloadLink({
  children,
  className,
  href,
  placement = "hero",
}: {
  children: ReactNode;
  className: string;
  href: string;
  placement?: string;
}) {
  const linkRef = useRef<HTMLAnchorElement>(null);
  const trackingBound = useRef(false);

  useEffect(() => {
    if (
      trackingBound.current ||
      !linkRef.current ||
      !initializeAnalytics()
    ) {
      return;
    }

    mixpanel.track_links(linkRef.current, "Download Clicked", {
      destination: "latest_dmg",
      platform: "macOS",
      placement,
      page_path: window.location.pathname,
      page_type: pageType(window.location.pathname),
      ...trafficSource(document.referrer),
    });
    trackingBound.current = true;
  }, [placement]);

  return (
    <a
      ref={linkRef}
      className={className}
      href={href}
      aria-label="Download the latest StickerPort DMG for macOS"
    >
      {children}
    </a>
  );
}
