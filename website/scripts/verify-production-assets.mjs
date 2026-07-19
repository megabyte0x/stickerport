import assert from "node:assert/strict";

const baseUrl = new URL(
  process.argv[2] ?? "https://stickerport.megabyte.sh/",
);

async function fetchBody(url) {
  const response = await fetch(url, {
    headers: {
      "user-agent": "StickerPort production verifier",
    },
    redirect: "follow",
  });
  const body = await response.text();

  assert.equal(
    response.status,
    200,
    `${url} returned ${response.status}: ${body.slice(0, 120)}`,
  );

  return { body, response };
}

const { body: html } = await fetchBody(baseUrl);
const assetUrls = [
  ...new Set(
    [...html.matchAll(/(?:href|src)="([^"]*\/assets\/[^"]+)"/g)].map(
      ([, value]) => new URL(value, baseUrl).href,
    ),
  ),
];

assert.ok(
  assetUrls.some((url) => url.endsWith(".css")),
  "The landing page did not reference a CSS asset.",
);
assert.ok(
  assetUrls.some((url) => url.endsWith(".js")),
  "The landing page did not reference a JavaScript asset.",
);

for (const assetUrl of assetUrls) {
  const { body, response } = await fetchBody(assetUrl);
  const contentType = response.headers.get("content-type") ?? "";

  assert.ok(body.length > 100, `${assetUrl} returned an unexpectedly short body.`);

  if (assetUrl.endsWith(".css")) {
    assert.match(contentType, /^text\/css\b/);
    assert.match(body, /\.landing-shell\b/);
  }

  if (assetUrl.endsWith(".js")) {
    assert.match(contentType, /(?:java|ecma)script/);
  }
}

console.log(
  `Verified ${assetUrls.length} production assets at ${baseUrl.origin}.`,
);
