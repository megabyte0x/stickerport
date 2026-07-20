import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import test from "node:test";

const DOWNLOAD_URL = "/download";
const LATEST_DMG_URL =
  "https://github.com/megabyte0x/stickerport/releases/latest/download/StickerPort.dmg";
const ogImage = new URL("../public/og.png", import.meta.url);
const publicSignalTutorial = new URL(
  "../public/signal-sticker-tutorial.mp4",
  import.meta.url,
);
const appSignalTutorial = new URL(
  "../../StickerBridgeMac/Resources/SignalStickerTutorial.mp4",
  import.meta.url,
);

async function render(path = "/") {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request(new URL(path, "http://localhost/"), {
      headers: { accept: "text/html" },
    }),
    {
      ASSETS: {
        fetch: async () => new Response("Not found", { status: 404 }),
      },
    },
    {
      waitUntil() {},
      passThroughOnException() {},
    },
  );
}

test("server-renders the StickerPort download hero", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

  const html = await response.text();
  assert.match(html, /<title>StickerPort — WhatsApp stickers for Signal<\/title>/i);
  assert.match(html, /Bring your WhatsApp stickers to Signal\./);
  assert.match(html, /Everything stays on your Mac\./);
  assert.match(html, /Download for Mac/);
  assert.match(html, /macOS 15 or later/);
  assert.doesNotMatch(html, /macOS 15 or later · v0\.1\.0/);
  assert.match(html, /On-device/);
  assert.match(html, /Read-only/);
  assert.ok(html.includes(`href="${DOWNLOAD_URL}"`));
  assert.match(
    html,
    /aria-label="Download the latest StickerPort DMG for macOS"/,
  );
  assert.equal(
    (html.match(/src="\/stickerport-icon\.png"/g) ?? []).length,
    2,
  );
  assert.doesNotMatch(
    html,
    /\/_vinext\/image\?[^"']*stickerport-icon(?:\.png|%2Epng)/i,
  );
  assert.doesNotMatch(html, /codex-preview|Building your site|SkeletonPreview/);
  assert.doesNotMatch(html, /automatic Signal upload|direct Signal install/i);
});

test("redirects the download button to the pipeline-verified stable DMG", async (t) => {
  const originalFetch = globalThis.fetch;
  t.after(() => {
    globalThis.fetch = originalFetch;
  });

  globalThis.fetch = async () => {
    assert.fail("The download route must not depend on the GitHub API.");
  };

  const response = await render("/download");
  assert.equal(response.status, 307);
  assert.equal(response.headers.get("location"), LATEST_DMG_URL);
});

test("ships the validated StickerPort social card", async () => {
  await access(ogImage);
  const image = await readFile(ogImage);
  assert.deepEqual(
    [...image.subarray(0, 8)],
    [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
  );
  assert.equal(image.readUInt32BE(16), 1200);
  assert.equal(image.readUInt32BE(20), 630);

  const response = await render();
  const html = await response.text();
  assert.match(html, /property="og:image"/);
  assert.match(html, /name="twitter:image"/);
  assert.match(html, /http:\/\/localhost\/og\.png/);
});

test("renders the StickerPort-to-Signal handoff guide with the app tutorial", async () => {
  const response = await render();
  const html = await response.text();

  assert.match(html, /class="mac-window"/);
  assert.match(html, /class="window-toolbar"/);
  assert.match(html, /class="handoff-guide"/);
  assert.match(html, /Requirements/);
  assert.match(html, /WhatsApp Desktop/);
  assert.match(html, /Signal Desktop/);
  assert.match(html, /First, in StickerPort/);
  assert.match(html, /Quit WhatsApp/);
  assert.match(html, /Allow folder access/);
  assert.match(html, /Pick your stickers/);
  assert.match(html, /Create the Signal folder/);
  assert.match(html, /Then, in Signal/);
  assert.match(html, /Upload and install the pack/);
  assert.ok(html.includes('src="/signal-sticker-tutorial.mp4"'));
  assert.match(html, /aria-label="Signal sticker pack tutorial video"/);
  assert.match(html, /autoPlay=""/);
  assert.match(html, /controls=""/);
  assert.match(html, /loop=""/);
  assert.match(html, /muted=""/);
  assert.match(html, /playsInline=""/);

  const body = html.slice(html.indexOf("<body"));
  assert.ok(body.indexOf("Requirements") < body.indexOf("First, in StickerPort"));
  assert.ok(body.indexOf("First, in StickerPort") < body.indexOf("Then, in Signal"));
  assert.doesNotMatch(
    body,
    /automatic Signal upload|direct Signal install/i,
  );

  const [publicVideo, appVideo] = await Promise.all([
    readFile(publicSignalTutorial),
    readFile(appSignalTutorial),
  ]);
  assert.deepEqual(publicVideo, appVideo);
});

test("locks the page to one responsive viewport and preserves accessibility", async () => {
  const [css, layout, config, analytics, packageJson] = await Promise.all([
    readFile(new URL("../app/globals.css", import.meta.url), "utf8"),
    readFile(new URL("../app/layout.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/site-config.ts", import.meta.url), "utf8"),
    readFile(new URL("../app/analytics.tsx", import.meta.url), "utf8"),
    readFile(new URL("../package.json", import.meta.url), "utf8"),
  ]);

  assert.match(css, /html,\s*body\s*\{[^}]*overflow:\s*clip/s);
  assert.match(css, /height:\s*100svh/);
  assert.match(css, /height:\s*100dvh/);
  assert.match(css, /@media\s*\(prefers-reduced-motion:\s*reduce\)/);
  assert.match(css, /@media\s*\(prefers-reduced-transparency:\s*reduce\)/);
  assert.match(css, /@media\s*\(prefers-contrast:\s*more\)/);
  assert.match(css, /\.download-button:active/);
  assert.match(css, /\.download-button:focus-visible/);
  assert.doesNotMatch(css, /animation[^;]*infinite/i);
  assert.match(config, /StickerPort — WhatsApp stickers for Signal/);
  assert.match(config, /downloadUrl:\s*"\/download"/);
  assert.doesNotMatch(config, /releases\/download\/v\d|StickerPort-\d[^"]*\.dmg/);
  assert.match(layout, /generateMetadata/);
  assert.match(layout, /requestOrigin/);
  assert.match(layout, /siteConfig\.title/);
  assert.match(layout, /stickerport-icon\.png/);
  assert.match(layout, /<Analytics \/>/);
  assert.match(analytics, /Landing Page Viewed/);
  assert.match(analytics, /Download Clicked/);
  assert.match(analytics, /autocapture:\s*false/);
  assert.match(analytics, /disable_persistence:\s*true/);
  assert.match(analytics, /ip:\s*false/);
  assert.match(analytics, /record_sessions_percent:\s*0/);
  assert.match(analytics, /ignore_dnt:\s*false/);
  assert.match(analytics, /NEXT_PUBLIC_MIXPANEL_TOKEN/);
  assert.doesNotMatch(packageJson, /react-loading-skeleton/);

  await access(new URL("../public/stickerport-icon.png", import.meta.url));
  await assert.rejects(
    access(new URL("../app/_sites-preview", import.meta.url)),
  );
});
