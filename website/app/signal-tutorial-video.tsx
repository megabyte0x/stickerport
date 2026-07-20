"use client";

import { useEffect, useRef } from "react";

export function SignalTutorialVideo() {
  const videoRef = useRef<HTMLVideoElement>(null);

  useEffect(() => {
    const video = videoRef.current;
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

    if (!video) {
      return;
    }

    const syncPlayback = () => {
      if (reducedMotion.matches) {
        video.pause();
        video.currentTime = 0;
        return;
      }

      void video.play().catch(() => {
        // Native controls remain available if the browser blocks autoplay.
      });
    };

    syncPlayback();
    reducedMotion.addEventListener("change", syncPlayback);

    return () => {
      reducedMotion.removeEventListener("change", syncPlayback);
    };
  }, []);

  return (
    <video
      ref={videoRef}
      autoPlay
      controls
      loop
      muted
      playsInline
      preload="metadata"
      aria-label="Signal sticker pack tutorial video"
    >
      <source src="/signal-sticker-tutorial.mp4" type="video/mp4" />
      In Signal Desktop, choose File → Create/Upload Sticker Pack, select every
      exported sticker, add the pack details, then upload and install.
    </video>
  );
}
