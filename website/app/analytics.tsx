"use client";

import mixpanel from "mixpanel-browser/src/loaders/loader-module-core";
import { useEffect, useRef, type ReactNode } from "react";

const projectToken = process.env.NEXT_PUBLIC_MIXPANEL_TOKEN?.trim();
const apiHost =
  process.env.NEXT_PUBLIC_MIXPANEL_API_HOST?.trim() ??
  "https://api.mixpanel.com";

let analyticsInitialized = false;

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
  const pageViewTracked = useRef(false);

  useEffect(() => {
    if (pageViewTracked.current || !initializeAnalytics()) {
      return;
    }

    mixpanel.track("Landing Page Viewed", {
      page: "home",
    });
    pageViewTracked.current = true;
  }, []);

  return null;
}

export function TrackedDownloadLink({
  children,
  className,
  href,
}: {
  children: ReactNode;
  className: string;
  href: string;
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
      placement: "hero",
    });
    trackingBound.current = true;
  }, []);

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
