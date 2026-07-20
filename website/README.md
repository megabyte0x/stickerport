# StickerPort website

The public landing page for StickerPort, running on
[vinext](https://github.com/cloudflare/vinext) and Cloudflare Pages.

## Prerequisites

- Node.js `>=22.13.0`

## Quick Start

```bash
npm ci
npm run dev
npm run build
npm test
```

Use `npm run build:cloudflare` to produce the Cloudflare Pages advanced-mode
bundle in `dist/pages`. The Pages configuration template is
`wrangler.pages.jsonc`. The staging step also writes `_routes.json` so hashed
client assets bypass the Vinext Worker and are served directly by Pages.

## Analytics

The site sends two focused events to Mixpanel:

- `Page Viewed`
- `Download Clicked`

Both events include the page path/type, a coarse traffic source, and only the
referring hostname. Autocapture, session recording, IP geolocation, full
referrer URLs, query strings, and persistent visitor storage are disabled.
Configure the public project settings from `.env.example` before building:

```bash
cp .env.example .env.production.local
```

Set `NEXT_PUBLIC_MIXPANEL_TOKEN` to the Mixpanel project token and keep
`NEXT_PUBLIC_MIXPANEL_API_HOST` aligned with the project's data residency.

## SEO foundation

The production site includes:

- canonical metadata for `https://stickerport.megabyte.sh`
- SoftwareApplication, WebSite, Organization, HowTo, FAQ, article, and
  breadcrumb structured data
- `robots.txt`, `sitemap.xml`, and `llms.txt`
- a transfer guide, Signal requirements reference, privacy page, FAQ, and about
  page
- optional Google and Bing verification values in `.env.example`

The strategy, GEO analysis, competitor review, content calendar, roadmap, and
URL architecture are in `docs/seo/`.

## Cloudflare deployment

The production project is `stickerport` and the custom domain is
`stickerport.megabyte.sh`.

```bash
npm run deploy:cloudflare
npm run verify:production
```

## Included Shape

- edit site code under `app/`
- edit Cloudflare packaging under `scripts/prepare-cloudflare-pages.mjs`
- `.openai/hosting.json` declares optional Sites D1 and R2 bindings
- `vite.config.ts` simulates declared bindings for local development
- `db/schema.ts` starts intentionally empty
- `examples/d1/` contains an optional D1 example surface
- `drizzle.config.ts` supports local migration generation when needed

## Workspace Auth Headers

OpenAI workspace sites can read the current user's email from
`oai-authenticated-user-email`.

SIWC-authenticated workspace sites may also receive
`oai-authenticated-user-full-name` when the user's SIWC profile has a non-empty
`name` claim. The full-name value is percent-encoded UTF-8 and is accompanied by
`oai-authenticated-user-full-name-encoding: percent-encoded-utf-8`.

Treat the full name as optional and fall back to email when it is absent:

```tsx
import { headers } from "next/headers";

export default async function Home() {
  const requestHeaders = await headers();
  const email = requestHeaders.get("oai-authenticated-user-email");
  const encodedFullName = requestHeaders.get("oai-authenticated-user-full-name");
  const fullName =
    encodedFullName &&
    requestHeaders.get("oai-authenticated-user-full-name-encoding") ===
      "percent-encoded-utf-8"
      ? decodeURIComponent(encodedFullName)
      : null;

  const displayName = fullName ?? email;
  // ...
}
```

## Optional Dispatch-Owned ChatGPT Sign-In

Import the ready-to-use helpers from `app/chatgpt-auth.ts` when the site needs
optional or required ChatGPT sign-in:

- Use `getChatGPTUser()` for optional signed-in UI.
- Use `requireChatGPTUser(returnTo)` for server-rendered pages that should send
  anonymous visitors through Sign in with ChatGPT.
- Use `chatGPTSignInPath(returnTo)` and `chatGPTSignOutPath(returnTo)` for
  browser links or actions.
- Pass a same-origin relative `returnTo` path for the destination after sign-in
  or sign-out. The helper validates and safely encodes it.
- Mark protected pages with `export const dynamic = "force-dynamic"` because
  they depend on per-request identity headers.

Dispatch owns `/signin-with-chatgpt`, `/signout-with-chatgpt`, `/callback`, the
OAuth cookies, and identity header injection. Do not implement app routes for
those reserved paths. Routes that do not import and call the helper remain
anonymous-compatible.

SIWC establishes identity only; it does not prove workspace membership. Use the
Sites hosting platform's access policy controls for workspace-wide restrictions,
or enforce explicit server-side membership or allowlist checks.

Use SIWC for account pages, user-specific dashboards, saved records, and write
actions tied to the current ChatGPT user. Leave public content anonymous.

## Useful Commands

- `npm run dev`: start local development
- `npm run build`: verify the vinext build output
- `npm test`: build the Cloudflare output and verify routes, metadata, schema,
  discovery files, assets, and the stable download redirect
- `npm run db:generate`: generate Drizzle migrations after schema changes

## Learn More

- [vinext Documentation](https://github.com/cloudflare/vinext)
- [Drizzle D1 Guide](https://orm.drizzle.team/docs/get-started/d1-new)
