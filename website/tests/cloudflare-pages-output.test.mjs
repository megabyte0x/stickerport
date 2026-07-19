import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import test from "node:test";

const pagesOutput = new URL("../dist/pages/", import.meta.url);

test("stages a Cloudflare Pages advanced-mode deployment", async () => {
  await Promise.all([
    access(new URL("_worker.js", pagesOutput)),
    access(new URL("_worker/index.js", pagesOutput)),
    access(new URL("_worker/__vite_rsc_assets_manifest.js", pagesOutput)),
    access(new URL("_worker/ssr/index.js", pagesOutput)),
    access(new URL("assets/", pagesOutput)),
    access(new URL("stickerport-icon.png", pagesOutput)),
    access(new URL("wrangler.jsonc", pagesOutput)),
  ]);
  await assert.rejects(access(new URL("_worker/wrangler.json", pagesOutput)));

  const worker = await readFile(
    new URL("_worker/index.js", pagesOutput),
    "utf8",
  );
  assert.match(worker, /env\.ASSETS/);
  assert.match(worker, /export\s*\{\s*worker_entry_default as default\s*\}/);
});
