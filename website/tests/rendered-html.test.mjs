import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import test from "node:test";

const DOWNLOAD_URL = "/download";
const LATEST_RELEASE_API =
  "https://api.github.com/repos/megabyte0x/stickerport/releases/latest";
const LATEST_DMG_URL =
  "https://github.com/megabyte0x/stickerport/releases/download/v0.2.0/StickerPort-0.2.0.dmg";
const ogImage = new URL("../public/og.png", import.meta.url);
const stickerAssets = [
  "cuppy-smile.webp",
  "cuppy-love.webp",
  "cuppy-workhard.webp",
  "cuppy-hi.webp",
];

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

test("redirects the download button to the latest published DMG", async (t) => {
  const originalFetch = globalThis.fetch;
  t.after(() => {
    globalThis.fetch = originalFetch;
  });

  globalThis.fetch = async (input, init) => {
    const url = input instanceof Request ? input.url : String(input);
    assert.equal(url, LATEST_RELEASE_API);
    assert.deepEqual(init?.headers, {
      Accept: "application/vnd.github+json",
      "User-Agent": "StickerPort-Website",
      "X-GitHub-Api-Version": "2022-11-28",
    });
    return Response.json({
      assets: [
        {
          name: "StickerPort-0.2.0.dmg.sha256",
          browser_download_url: `${LATEST_DMG_URL}.sha256`,
        },
        {
          name: "StickerPort-0.2.0.dmg",
          browser_download_url: LATEST_DMG_URL,
        },
      ],
    });
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

test("renders real WhatsApp sample stickers in a macOS app frame", async () => {
  await Promise.all(
    stickerAssets.map((asset) =>
      access(new URL(`../public/stickers/${asset}`, import.meta.url)),
    ),
  );

  const response = await render();
  const html = await response.text();

  assert.match(html, /class="mac-window"/);
  assert.match(html, /class="window-toolbar"/);
  assert.match(html, /class="sticker-shelf"/);
  for (const asset of stickerAssets) {
    assert.ok(html.includes(`src="/stickers/${asset}"`));
  }
  const body = html.slice(html.indexOf("<body"));
  assert.match(body, /Your collection/);
  assert.doesNotMatch(
    body,
    /4 sample stickers|Local-only|No account|Official Cuppy sample artwork|Sticker source/,
  );
  assert.doesNotMatch(html, /😂|🫶|😎/);
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
