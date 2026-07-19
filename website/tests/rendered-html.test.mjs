import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import test from "node:test";

const DOWNLOAD_URL =
  "https://github.com/megabyte0x/stickerport/releases/download/v0.1.0/StickerPort-0.1.0.dmg";
const ogImage = new URL("../public/og.png", import.meta.url);

async function render() {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request("http://localhost/", {
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
  assert.match(html, /macOS 15 or later · v0\.1\.0/);
  assert.match(html, /Read-only/);
  assert.match(html, /Local-only/);
  assert.match(html, /No account/);
  assert.ok(html.includes(`href="${DOWNLOAD_URL}"`));
  assert.match(
    html,
    /aria-label="Download StickerPort 0\.1\.0 DMG for macOS"/,
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

test("ships the validated StickerPort social card", async () => {
  await access(ogImage);
  const response = await render();
  const html = await response.text();
  assert.match(html, /property="og:image"/);
  assert.match(html, /name="twitter:image"/);
  assert.match(html, /http:\/\/localhost\/og\.png/);
});

test("locks the page to one responsive viewport and preserves accessibility", async () => {
  const [css, layout, config, packageJson] = await Promise.all([
    readFile(new URL("../app/globals.css", import.meta.url), "utf8"),
    readFile(new URL("../app/layout.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/site-config.ts", import.meta.url), "utf8"),
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
  assert.match(config, /StickerPort-0\.1\.0\.dmg/);
  assert.match(layout, /generateMetadata/);
  assert.match(layout, /requestOrigin/);
  assert.match(layout, /siteConfig\.title/);
  assert.match(layout, /stickerport-icon\.png/);
  assert.doesNotMatch(packageJson, /react-loading-skeleton/);

  await access(new URL("../public/stickerport-icon.png", import.meta.url));
  await assert.rejects(
    access(new URL("../app/_sites-preview", import.meta.url)),
  );
});
