# StickerPort Landing Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and publish a single-window Apple-inspired landing page that explains StickerPort’s WhatsApp-to-Signal workflow and starts the StickerPort DMG download directly from its primary button.

**Architecture:** Add an isolated `website/` Vinext/React site inside a dedicated Git worktree so the existing Swift/Xcode application remains untouched. The page is a server-rendered, single-route product hero with no client state: copy and external URLs live in one typed config file, presentation lives in one page component and one stylesheet, and the DMG remains hosted as the verified GitHub release asset. Sites supplies the Cloudflare-compatible build and hosting lane.

**Tech Stack:** Git worktrees, TypeScript 5.9, React 19, Next-compatible Vinext, Vite 8, CSS, Node test runner, OpenAI Sites hosting

## Global Constraints

- FIRST create and save this plan; do not change website product code before the plan handoff is accepted.
- Execute implementation in `.worktrees/stickerport-site` on branch `codex/stickerport-site` using `superpowers:using-git-worktrees`.
- Keep the existing Swift, XcodeGen, release, and DMG files unchanged.
- The site has exactly one route and one primary action.
- The visible headline must say: `Bring your WhatsApp stickers to Signal.`
- The primary button must navigate directly to `https://github.com/megabyte0x/stickerport/releases/download/v0.1.0/StickerPort-0.1.0.dmg`.
- The page must fit a single browser window without vertical or horizontal scrolling; use `100svh`/`100dvh`, `overflow: clip`, responsive type, and height-based reductions.
- The supported platform copy is `macOS 15 or later · v0.1.0`.
- Product claims are limited to verified behavior: local-only processing, read-only WhatsApp access, no account, and a Signal-ready export folder.
- Do not claim direct Signal installation, automatic Signal upload, animated-sticker support, or affiliation with WhatsApp or Signal.
- Use Apple-style restraint: system typography, size-specific tracking, translucent material depth, immediate press feedback, short non-looping motion, and generous negative space.
- Support `prefers-reduced-motion`, `prefers-reduced-transparency`, `prefers-contrast`, keyboard focus, touch input, and dark appearance.
- Do not ship model-authored SVG illustrations, trackers, analytics, authentication, persistence, forms, or speculative product sections.
- Use the existing StickerPort app icon as the only product image in the page UI.
- Validate the direct DMG response, production build, server-rendered HTML contract, and hosting archive before publishing.
- Publish privately first through Sites. If only shared or public access is available, request explicit approval for the resolved access level before deployment.

## Design Reference Decisions

- Apple design supplies the full-viewport composition, system typography, tight display tracking, quiet glass surfaces, instant button press response, and reduced-motion behavior.
- [Sticker.ly](https://sticker.ly/) supplies the product-first verb, immediate download action, and expressive sticker cluster rather than a long feature narrative.
- [Signal](https://signal.org/?lang=en_gb) supplies bold, plain-language messaging and the privacy-forward tone.
- [Signal sticker guidance](https://support.signal.org/hc/en-us/articles/360031836512-Stickers) supports describing the output as a Signal-ready folder for Signal Desktop’s official sticker creator, not an automatic install.
- The selected direction is **Glass Handoff**: an airy warm-white canvas, black editorial headline, green-to-blue ambient light, a glass StickerPort card, and a compact path of generic emoji stickers moving visually from a WhatsApp text badge to a Signal text badge. No WhatsApp or Signal logos are used.

## File Map

- Modify `.gitignore` — ignore the project-local worktree directory.
- Create `website/` — self-contained Sites/Vinext project copied from the bundled starter.
- Create `website/app/site-config.ts` — single source for product copy, release version, repository URL, and direct DMG URL.
- Replace `website/app/page.tsx` — semantic one-page hero and direct download anchor.
- Replace `website/app/layout.tsx` — site metadata, app icon, and system-font root layout.
- Replace `website/app/globals.css` — full-viewport responsive design, materials, motion, and accessibility media queries.
- Replace `website/tests/rendered-html.test.mjs` — production SSR, download-link, no-scroll, asset, and accessibility contract tests.
- Create `website/public/stickerport-icon.png` — copy of the existing 1024 px StickerPort app icon.
- Optionally create `website/public/og.png` — one validated image-generation result for social previews; omit the image metadata if validation fails twice.
- Modify `website/package.json` and `website/package-lock.json` — rename the project and remove the starter-only loading dependency.
- Modify `website/.openai/hosting.json` — persist the Sites `project_id` while leaving `d1` and `r2` null.
- Delete `website/app/_sites-preview/` and the generic starter SVG assets after the real page replaces them.

---

### Task 1: Commit the Plan and Create the Isolated Worktree

**Files:**
- Modify: `.gitignore`
- Existing: `docs/superpowers/plans/2026-07-19-stickerport-landing-page.md`

**Interfaces:**
- Consumes: current repository at commit `9a45ecf8c13875353c11c3a831f660153eeddfa9`, including the existing StickerPort macOS interface refresh
- Produces: clean worktree `.worktrees/stickerport-site` on branch `codex/stickerport-site`

- [ ] **Step 1: Confirm the repository is not already a linked worktree**

Run:

```bash
git rev-parse --git-dir
git rev-parse --git-common-dir
git rev-parse --show-superproject-working-tree
git branch --show-current
```

Expected: `.git` and `.git` for the first two commands, an empty superproject result, and `codex/sticker-ui-refresh` as the current branch.

- [ ] **Step 2: Verify the project-local worktree directory is not yet ignored**

Run:

```bash
git check-ignore -q .worktrees/
```

Expected: exit status `1` because `.worktrees/` is not yet present in `.gitignore`.

- [ ] **Step 3: Add the worktree directory to `.gitignore`**

Append exactly this line with `apply_patch`:

```gitignore
.worktrees/
```

- [ ] **Step 4: Confirm only the intended planning files will be staged**

Run:

```bash
git status --short
```

Expected: `.gitignore` and `docs/superpowers/plans/2026-07-19-stickerport-landing-page.md` are visible along with the user’s pre-existing untracked research/plans. Do not stage the pre-existing untracked files.

- [ ] **Step 5: Commit the plan and worktree safety rule**

Run:

```bash
git add .gitignore docs/superpowers/plans/2026-07-19-stickerport-landing-page.md
git commit -m "docs: plan StickerPort landing page"
```

Expected: one commit containing exactly two files.

- [ ] **Step 6: Verify `.worktrees/` is now ignored**

Run:

```bash
git check-ignore -q .worktrees/
```

Expected: exit status `0`.

- [ ] **Step 7: Create the implementation worktree and branch**

Run:

```bash
git worktree add .worktrees/stickerport-site -b codex/stickerport-site
```

Expected: Git reports a new worktree checked out on `codex/stickerport-site`.

- [ ] **Step 8: Verify the worktree branch and clean baseline**

Run from `.worktrees/stickerport-site`:

```bash
git branch --show-current
git status --short
```

Expected: `codex/stickerport-site` and no output from `git status --short`.

- [ ] **Step 9: Run the existing macOS unit-test baseline**

Run:

```bash
xcodegen generate
xcodebuild -project StickerBridge.xcodeproj -scheme StickerBridgeMac -destination 'platform=macOS' -only-testing:StickerBridgeMacTests test
```

Expected: `** TEST SUCCEEDED **`. If the existing suite fails before website changes, stop and report the failure instead of continuing.

### Task 2: Scaffold the Sites Project Without Nesting a Git Repository

**Files:**
- Create: `website/**`

**Interfaces:**
- Consumes: bundled Sites initializer and Vinext starter
- Produces: installable `website/` project with `npm run dev`, `npm run build`, and `npm test`

- [ ] **Step 1: Create a known empty initializer target**

Run:

```bash
rm -rf /private/tmp/stickerport-site-starter
mkdir /private/tmp/stickerport-site-starter
```

Expected: `/private/tmp/stickerport-site-starter` exists and is empty. This path is task-owned temporary setup state.

- [ ] **Step 2: Initialize the bundled Sites starter in the temporary directory**

Run:

```bash
/Users/megabyte0x/.codex/plugins/cache/openai-bundled/sites/0.1.30/scripts/init-site.sh /private/tmp/stickerport-site-starter
```

Expected: `npm ci` completes successfully and the temporary directory contains `app/`, `public/`, `tests/`, `package.json`, and `.openai/hosting.json`.

- [ ] **Step 3: Copy the starter source into `website/` without its temporary Git metadata or dependencies**

Run:

```bash
mkdir website
rsync -a --exclude='.git' --exclude='node_modules' /private/tmp/stickerport-site-starter/ website/
```

Expected: `website/.git` does not exist and `git status --short website` lists the starter source files.

- [ ] **Step 4: Install dependencies in the repository-owned site**

Run:

```bash
npm ci --ignore-scripts --prefer-offline --no-audit --no-fund
```

Working directory: `website/`

Expected: dependencies install with exit status `0`.

- [ ] **Step 5: Start the development server and open the starter**

Start the development server in a retained session:

```bash
npm run dev
```

Working directory: `website/`

Expected: the server prints one healthy Local URL. Keep this session running through implementation and hosting, and open that exact URL once in the Codex in-app browser before editing product files.

- [ ] **Step 6: Run the unmodified starter test**

Run:

```bash
npm test
```

Working directory: `website/`

Expected: the two starter loading-skeleton tests pass.

- [ ] **Step 7: Commit the isolated starter scaffold**

Run from the worktree root:

```bash
git add website
git commit -m "chore: scaffold StickerPort website"
```

Expected: one scaffold commit with no Swift/Xcode changes.

### Task 3: Define the Failing Landing-Page Contract

**Files:**
- Replace: `website/tests/rendered-html.test.mjs`

**Interfaces:**
- Consumes: built worker at `website/dist/server/index.js`
- Produces: contract for the exact headline, direct download URL, metadata, icon, viewport lock, accessibility media queries, and removal of starter content

- [ ] **Step 1: Replace the starter test with the final product contract**

Write exactly:

```js
import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import test from "node:test";

const DOWNLOAD_URL =
  "https://github.com/megabyte0x/stickerport/releases/download/v0.1.0/StickerPort-0.1.0.dmg";

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
  assert.doesNotMatch(html, /codex-preview|Building your site|SkeletonPreview/);
  assert.doesNotMatch(html, /automatic Signal upload|direct Signal install/i);
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
```

- [ ] **Step 2: Run the contract to verify it fails against the starter**

Run:

```bash
npm test
```

Working directory: `website/`

Expected: FAIL because the starter does not render the StickerPort headline or direct DMG link.

### Task 4: Implement the Single-Window Glass Handoff Page

**Files:**
- Create: `website/app/site-config.ts`
- Replace: `website/app/page.tsx`
- Replace: `website/app/layout.tsx`
- Replace: `website/app/globals.css`
- Create: `website/public/stickerport-icon.png`
- Modify: `website/package.json`
- Modify: `website/package-lock.json`
- Delete: `website/app/_sites-preview/SkeletonPreview.tsx`
- Delete: `website/app/_sites-preview/preview.css`
- Delete: `website/public/favicon.svg`
- Delete: `website/public/file.svg`
- Delete: `website/public/globe.svg`
- Delete: `website/public/window.svg`

**Interfaces:**
- Consumes: `siteConfig` values in the server-rendered page and layout
- Produces: `siteConfig.downloadUrl`, one semantic `<main>`, one primary `<a>`, and CSS that never creates a scrolling page

- [ ] **Step 1: Add the typed product and release configuration**

Create `website/app/site-config.ts` with:

```ts
export const siteConfig = {
  name: "StickerPort",
  title: "StickerPort — WhatsApp stickers for Signal",
  description:
    "Bring your WhatsApp stickers to Signal with a local-only, read-only macOS app.",
  headline: "Bring your WhatsApp stickers to Signal.",
  supportingCopy:
    "StickerPort finds the stickers already on your Mac and prepares a Signal-ready folder. Everything stays on your Mac.",
  version: "0.1.0",
  compatibility: "macOS 15 or later · v0.1.0",
  downloadUrl:
    "https://github.com/megabyte0x/stickerport/releases/download/v0.1.0/StickerPort-0.1.0.dmg",
  repositoryUrl: "https://github.com/megabyte0x/stickerport",
} as const;
```

- [ ] **Step 2: Replace the starter page with the semantic product hero**

Replace `website/app/page.tsx` with:

```tsx
import Image from "next/image";
import { siteConfig } from "./site-config";

const stickers = [
  { emoji: "😂", className: "sticker sticker--laugh" },
  { emoji: "🫶", className: "sticker sticker--love" },
  { emoji: "😎", className: "sticker sticker--cool" },
] as const;

export default function Home() {
  return (
    <main className="landing-shell">
      <div className="ambient ambient--green" aria-hidden="true" />
      <div className="ambient ambient--blue" aria-hidden="true" />

      <header className="site-header" aria-label="StickerPort">
        <a className="brand" href="#top" aria-label="StickerPort home">
          <Image
            className="brand-icon"
            src="/stickerport-icon.png"
            alt=""
            width={44}
            height={44}
            priority
          />
          <span className="brand-name">{siteConfig.name}</span>
        </a>
        <span className="brand-note">Private by design · Made for Mac</span>
      </header>

      <section className="hero" id="top" aria-labelledby="hero-title">
        <div className="hero-copy">
          <p className="eyebrow">WhatsApp → Signal. On your Mac.</p>
          <h1 id="hero-title">{siteConfig.headline}</h1>
          <p className="lede">{siteConfig.supportingCopy}</p>

          <div className="actions">
            <a
              className="download-button"
              href={siteConfig.downloadUrl}
              download={`StickerPort-${siteConfig.version}.dmg`}
              aria-label={`Download StickerPort ${siteConfig.version} DMG for macOS`}
            >
              <span className="download-symbol" aria-hidden="true">
                ↓
              </span>
              <span>Download for Mac</span>
            </a>
            <p className="compatibility">{siteConfig.compatibility}</p>
          </div>

          <ul className="trust-list" aria-label="Privacy promises">
            <li>Read-only</li>
            <li>Local-only</li>
            <li>No account</li>
          </ul>
        </div>

        <figure
          className="handoff"
          aria-label="StickerPort prepares WhatsApp stickers for Signal"
        >
          <span className="platform platform--whatsapp">WhatsApp</span>
          <div className="handoff-line" aria-hidden="true" />

          {stickers.map((sticker) => (
            <span
              className={sticker.className}
              aria-hidden="true"
              key={sticker.emoji}
            >
              {sticker.emoji}
            </span>
          ))}

          <div className="app-card">
            <Image
              className="app-card-icon"
              src="/stickerport-icon.png"
              alt="StickerPort app icon"
              width={112}
              height={112}
              priority
            />
            <div>
              <strong>StickerPort</strong>
              <span>Signal-ready folder</span>
            </div>
            <span className="ready-dot" aria-hidden="true" />
          </div>

          <span className="platform platform--signal">Signal</span>
        </figure>
      </section>

      <footer className="site-footer">
        <span>Not affiliated with WhatsApp or Signal.</span>
        <a href={siteConfig.repositoryUrl}>View source</a>
      </footer>
    </main>
  );
}
```

- [ ] **Step 3: Replace the starter layout and metadata**

Replace `website/app/layout.tsx` with:

```tsx
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
```

- [ ] **Step 4: Implement the full-viewport Apple-inspired design**

Replace `website/app/globals.css` with:

```css
@import "tailwindcss";

:root {
  color-scheme: light;
  --canvas: #f7f7f4;
  --ink: #11120f;
  --muted: #65675f;
  --hairline: rgba(17, 18, 15, 0.1);
  --glass: rgba(255, 255, 255, 0.68);
  --glass-strong: rgba(255, 255, 255, 0.86);
  --green: #21c77a;
  --blue: #3a76f0;
  --shadow: 0 28px 70px rgba(39, 44, 35, 0.15);
}

* {
  box-sizing: border-box;
}

html,
body {
  width: 100%;
  height: 100%;
  margin: 0;
  overflow: clip;
}

body {
  background: var(--canvas);
  color: var(--ink);
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display",
    "SF Pro Text", system-ui, sans-serif;
  text-rendering: optimizeLegibility;
  -webkit-font-smoothing: antialiased;
}

a {
  color: inherit;
  text-decoration: none;
}

.landing-shell {
  position: relative;
  isolation: isolate;
  display: grid;
  grid-template-rows: auto minmax(0, 1fr) auto;
  width: 100%;
  height: 100svh;
  min-height: 0;
  overflow: hidden;
  padding: clamp(1rem, 2.8vh, 2rem) clamp(1rem, 5vw, 5rem);
  background:
    radial-gradient(circle at 48% 42%, rgba(255, 255, 255, 0.92), transparent 42%),
    linear-gradient(135deg, #fbfbf8 0%, var(--canvas) 52%, #f1f3ef 100%);
}

@supports (height: 100dvh) {
  .landing-shell {
    height: 100dvh;
  }
}

.ambient {
  position: absolute;
  z-index: -2;
  width: min(44vw, 42rem);
  aspect-ratio: 1;
  border-radius: 50%;
  filter: blur(90px);
  opacity: 0.22;
  pointer-events: none;
}

.ambient--green {
  top: -22%;
  right: 24%;
  background: var(--green);
}

.ambient--blue {
  right: -12%;
  bottom: -34%;
  background: var(--blue);
}

.site-header,
.site-footer {
  position: relative;
  z-index: 4;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.brand {
  display: inline-flex;
  align-items: center;
  gap: 0.72rem;
  border-radius: 0.9rem;
}

.brand:focus-visible,
.site-footer a:focus-visible {
  outline: 3px solid color-mix(in srgb, var(--blue) 68%, white);
  outline-offset: 5px;
}

.brand-icon {
  width: clamp(2.25rem, 4vw, 2.75rem);
  height: auto;
  border-radius: 22%;
  box-shadow: 0 10px 24px rgba(17, 18, 15, 0.16);
}

.brand-name {
  font-size: 1.02rem;
  font-weight: 720;
  letter-spacing: -0.025em;
}

.brand-note {
  color: var(--muted);
  font-size: 0.76rem;
  font-weight: 600;
  letter-spacing: 0.04em;
}

.hero {
  position: relative;
  z-index: 1;
  display: grid;
  grid-template-columns: minmax(0, 0.94fr) minmax(19rem, 1.06fr);
  align-items: center;
  gap: clamp(2rem, 6vw, 7rem);
  min-height: 0;
}

.hero-copy {
  position: relative;
  z-index: 3;
  max-width: 49rem;
  animation: materialize 560ms cubic-bezier(0.16, 1, 0.3, 1) both;
}

.eyebrow {
  margin: 0 0 clamp(0.75rem, 1.8vh, 1.15rem);
  color: #2d7958;
  font-size: clamp(0.72rem, 1vw, 0.82rem);
  font-weight: 760;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

h1 {
  max-width: 12ch;
  margin: 0;
  font-size: clamp(3rem, min(7vw, 9vh), 6.75rem);
  font-weight: 760;
  letter-spacing: -0.066em;
  line-height: 0.93;
  text-wrap: balance;
}

.lede {
  max-width: 37rem;
  margin: clamp(1rem, 2.3vh, 1.55rem) 0 0;
  color: var(--muted);
  font-size: clamp(1rem, 1.4vw, 1.18rem);
  font-weight: 470;
  letter-spacing: -0.012em;
  line-height: 1.5;
}

.actions {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-top: clamp(1.2rem, 3vh, 2rem);
}

.download-button {
  display: inline-flex;
  min-height: 3.35rem;
  align-items: center;
  justify-content: center;
  gap: 0.72rem;
  padding: 0.92rem 1.35rem;
  border: 1px solid rgba(255, 255, 255, 0.38);
  border-radius: 1.1rem;
  background: var(--ink);
  box-shadow: 0 14px 30px rgba(17, 18, 15, 0.2);
  color: #ffffff;
  font-size: 0.98rem;
  font-weight: 720;
  letter-spacing: -0.018em;
  touch-action: manipulation;
  transition:
    transform 180ms cubic-bezier(0.16, 1, 0.3, 1),
    box-shadow 180ms cubic-bezier(0.16, 1, 0.3, 1),
    background 180ms ease;
}

.download-button:hover {
  transform: translateY(-2px);
  box-shadow: 0 18px 38px rgba(17, 18, 15, 0.24);
}

.download-button:active {
  transform: scale(0.97);
  box-shadow: 0 8px 18px rgba(17, 18, 15, 0.2);
  transition-duration: 90ms;
}

.download-button:focus-visible {
  outline: 3px solid color-mix(in srgb, var(--blue) 70%, white);
  outline-offset: 4px;
}

.download-symbol {
  display: grid;
  width: 1.55rem;
  height: 1.55rem;
  place-items: center;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.14);
  font-size: 1rem;
  line-height: 1;
}

.compatibility {
  margin: 0;
  color: var(--muted);
  font-size: 0.78rem;
  font-weight: 600;
  letter-spacing: 0.015em;
}

.trust-list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.55rem;
  margin: clamp(1rem, 2.2vh, 1.45rem) 0 0;
  padding: 0;
  list-style: none;
}

.trust-list li {
  padding: 0.48rem 0.72rem;
  border: 1px solid var(--hairline);
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.42);
  color: var(--muted);
  font-size: 0.72rem;
  font-weight: 660;
  letter-spacing: 0.02em;
  backdrop-filter: blur(14px) saturate(130%);
}

.handoff {
  position: relative;
  width: min(43vw, 39rem);
  aspect-ratio: 1.12;
  margin: 0;
  justify-self: end;
  animation: materialize 700ms 70ms cubic-bezier(0.16, 1, 0.3, 1) both;
}

.handoff-line {
  position: absolute;
  top: 49%;
  left: 8%;
  width: 84%;
  height: 2px;
  background: linear-gradient(90deg, var(--green), rgba(17, 18, 15, 0.08), var(--blue));
  transform: rotate(-9deg);
  transform-origin: center;
}

.handoff-line::after {
  position: absolute;
  top: 50%;
  right: -0.2rem;
  width: 0.7rem;
  height: 0.7rem;
  border-top: 2px solid var(--blue);
  border-right: 2px solid var(--blue);
  content: "";
  transform: translateY(-50%) rotate(45deg);
}

.platform {
  position: absolute;
  z-index: 4;
  padding: 0.62rem 0.85rem;
  border: 1px solid rgba(255, 255, 255, 0.62);
  border-radius: 999px;
  background: var(--glass-strong);
  box-shadow: 0 12px 28px rgba(17, 18, 15, 0.11);
  font-size: 0.74rem;
  font-weight: 760;
  letter-spacing: -0.012em;
  backdrop-filter: blur(20px) saturate(170%);
}

.platform--whatsapp {
  top: 57%;
  left: 0;
  color: #14794d;
}

.platform--signal {
  top: 29%;
  right: 0;
  color: #275fcd;
}

.app-card {
  position: absolute;
  z-index: 3;
  top: 21%;
  left: 23%;
  display: grid;
  grid-template-columns: auto 1fr auto;
  width: 58%;
  align-items: center;
  gap: clamp(0.7rem, 2vw, 1.1rem);
  padding: clamp(1rem, 2.4vw, 1.45rem);
  border: 1px solid rgba(255, 255, 255, 0.72);
  border-radius: clamp(1.45rem, 3vw, 2.2rem);
  background: var(--glass);
  box-shadow: var(--shadow);
  transform: rotate(-6deg);
  backdrop-filter: blur(30px) saturate(170%);
}

.app-card-icon {
  width: clamp(4rem, 9vw, 7rem);
  height: auto;
  border-radius: 24%;
  box-shadow: 0 16px 32px rgba(17, 18, 15, 0.2);
}

.app-card div {
  display: grid;
  gap: 0.3rem;
}

.app-card strong {
  font-size: clamp(1rem, 2vw, 1.35rem);
  letter-spacing: -0.04em;
}

.app-card span:not(.ready-dot) {
  color: var(--muted);
  font-size: clamp(0.62rem, 1vw, 0.78rem);
  font-weight: 600;
}

.ready-dot {
  width: 0.7rem;
  height: 0.7rem;
  border-radius: 50%;
  background: var(--green);
  box-shadow: 0 0 0 0.36rem color-mix(in srgb, var(--green) 18%, transparent);
}

.sticker {
  position: absolute;
  z-index: 5;
  display: grid;
  width: clamp(3.2rem, 7vw, 5.6rem);
  aspect-ratio: 1;
  place-items: center;
  border: 1px solid rgba(255, 255, 255, 0.84);
  border-radius: 34% 42% 31% 45%;
  background: var(--glass-strong);
  box-shadow: 0 16px 34px rgba(17, 18, 15, 0.13);
  font-size: clamp(1.65rem, 4vw, 3.2rem);
  backdrop-filter: blur(18px) saturate(150%);
}

.sticker--laugh {
  top: 4%;
  left: 8%;
  transform: rotate(10deg);
}

.sticker--love {
  right: 9%;
  bottom: 7%;
  transform: rotate(9deg);
}

.sticker--cool {
  bottom: 2%;
  left: 19%;
  transform: rotate(-13deg);
}

.site-footer {
  color: var(--muted);
  font-size: 0.68rem;
  font-weight: 570;
  letter-spacing: 0.018em;
}

.site-footer a {
  color: var(--ink);
  font-weight: 700;
}

@keyframes materialize {
  from {
    opacity: 0;
    transform: translateY(14px) scale(0.985);
    filter: blur(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
    filter: blur(0);
  }
}

@media (max-width: 820px) {
  .hero {
    grid-template-columns: minmax(0, 1fr);
  }

  .hero-copy {
    max-width: 42rem;
  }

  .handoff {
    position: absolute;
    right: -7rem;
    bottom: -4rem;
    width: min(70vw, 30rem);
    opacity: 0.43;
    transform: scale(0.9);
    transform-origin: bottom right;
  }

  .lede {
    max-width: 34rem;
  }
}

@media (max-width: 560px) {
  .landing-shell {
    padding-inline: 1rem;
  }

  .brand-note,
  .trust-list,
  .site-footer span {
    display: none;
  }

  h1 {
    max-width: 10ch;
    font-size: clamp(2.75rem, 14vw, 4.5rem);
  }

  .lede {
    max-width: 27rem;
    font-size: 0.98rem;
  }

  .actions {
    align-items: flex-start;
    flex-direction: column;
    gap: 0.68rem;
  }

  .handoff {
    right: -8rem;
    bottom: -5rem;
    width: 25rem;
    opacity: 0.25;
  }
}

@media (max-height: 700px) {
  .landing-shell {
    padding-block: 0.8rem;
  }

  .hero {
    gap: 1rem;
  }

  .eyebrow {
    margin-bottom: 0.6rem;
  }

  h1 {
    font-size: clamp(2.3rem, min(6vw, 7.8vh), 4.9rem);
  }

  .lede {
    margin-top: 0.8rem;
    font-size: 0.96rem;
  }

  .actions {
    margin-top: 1rem;
  }

  .trust-list {
    margin-top: 0.75rem;
  }

  .handoff {
    transform: scale(0.84);
    transform-origin: center right;
  }
}

@media (max-height: 560px) {
  .brand-note,
  .trust-list,
  .site-footer {
    display: none;
  }

  .handoff {
    transform: scale(0.7);
  }
}

@media (prefers-color-scheme: dark) {
  :root {
    color-scheme: dark;
    --canvas: #10110f;
    --ink: #f5f6f1;
    --muted: #a7aaa1;
    --hairline: rgba(255, 255, 255, 0.12);
    --glass: rgba(39, 41, 37, 0.68);
    --glass-strong: rgba(48, 51, 46, 0.88);
    --shadow: 0 28px 70px rgba(0, 0, 0, 0.36);
  }

  .landing-shell {
    background:
      radial-gradient(circle at 48% 42%, rgba(48, 52, 46, 0.72), transparent 42%),
      linear-gradient(135deg, #151714 0%, var(--canvas) 55%, #101616 100%);
  }

  .eyebrow {
    color: #6ee0a6;
  }

  .download-button {
    border-color: rgba(255, 255, 255, 0.14);
    background: #f3f4ef;
    color: #11120f;
  }

  .trust-list li {
    background: rgba(255, 255, 255, 0.06);
  }
}

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    scroll-behavior: auto !important;
    animation-duration: 1ms !important;
    animation-delay: 0ms !important;
    transition-duration: 1ms !important;
  }

  .hero-copy,
  .handoff {
    animation: none;
  }
}

@media (prefers-reduced-transparency: reduce) {
  .app-card,
  .platform,
  .sticker,
  .trust-list li {
    background: var(--canvas);
    backdrop-filter: none;
  }
}

@media (prefers-contrast: more) {
  .app-card,
  .platform,
  .sticker,
  .trust-list li {
    border: 2px solid var(--ink);
    background: var(--canvas);
  }

  .compatibility,
  .lede,
  .site-footer {
    color: var(--ink);
  }
}
```

- [ ] **Step 5: Copy the existing app icon into the website**

Run from the worktree root:

```bash
cp StickerBridgeMac/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png website/public/stickerport-icon.png
```

Expected: `file website/public/stickerport-icon.png` reports a PNG image.

- [ ] **Step 6: Remove the starter-only UI and generic assets**

Delete these exact files with `apply_patch`:

```text
website/app/_sites-preview/SkeletonPreview.tsx
website/app/_sites-preview/preview.css
website/public/favicon.svg
website/public/file.svg
website/public/globe.svg
website/public/window.svg
```

After both preview files are deleted, remove the empty `website/app/_sites-preview/` directory.

- [ ] **Step 7: Rename the project and remove the loading-skeleton dependency**

Run:

```bash
npm pkg set name=stickerport-site
npm uninstall react-loading-skeleton
```

Working directory: `website/`

Expected: `package.json` contains `"name": "stickerport-site"` and no `react-loading-skeleton` dependency; the lockfile is refreshed.

- [ ] **Step 8: Run the contract to verify the implementation passes**

Run:

```bash
npm test
```

Working directory: `website/`

Expected: all landing-page contract tests pass.

- [ ] **Step 9: Commit the working page**

Run from the worktree root:

```bash
git add website
git commit -m "feat: add StickerPort download landing page"
```

Expected: one product commit with no modifications outside `website/`.

### Task 5: Add a Validated Social Preview Without Blocking the Site

**Files:**
- Create when valid: `website/public/og.png`
- Modify when valid: `website/app/layout.tsx`
- Modify when valid: `website/tests/rendered-html.test.mjs`

**Interfaces:**
- Consumes: final Glass Handoff copy, palette, app icon, and motif
- Produces: a 1200×630 social card referenced by Open Graph and X metadata, or deliberately no image metadata if validation fails twice

- [ ] **Step 1: Add a failing social-card contract**

Add these assertions to `website/tests/rendered-html.test.mjs`:

```js
const ogImage = new URL("../public/og.png", import.meta.url);

test("ships the validated StickerPort social card", async () => {
  await access(ogImage);
  const response = await render();
  const html = await response.text();
  assert.match(html, /property="og:image"/);
  assert.match(html, /name="twitter:image"/);
  assert.match(html, /http:\/\/localhost\/og\.png/);
});
```

- [ ] **Step 2: Run the social-card contract to verify it fails**

Run:

```bash
npm test
```

Working directory: `website/`

Expected: FAIL because `website/public/og.png` does not exist and the metadata does not reference it.

- [ ] **Step 3: Generate exactly one social-card candidate**

Use `imagegen` with this exact prompt:

```text
Create a complete 1200x630 landscape social preview card for StickerPort, a macOS app. Match a refined Apple-inspired product landing page: warm off-white background (#F7F7F4), crisp near-black typography, subtle green-to-blue ambient light, generous negative space, and a central translucent glass card containing a dark rounded-square StickerPort-style portal icon. Add three small original generic emoji-like sticker faces flowing from a green “WhatsApp” text badge toward a blue “Signal” text badge. Include exactly this headline, spelled and punctuated exactly: “Bring your WhatsApp stickers to Signal.” Include the small product name “StickerPort”. Do not include WhatsApp or Signal logos, browser chrome, device frames, watermarks, extra text, or unrelated icons. The result must be legible as a Slack, X, and iMessage link preview.
```

Expected: one landscape image result, not multiple candidates.

- [ ] **Step 4: Inspect the candidate and apply the bounded fallback**

Inspect the image at original detail. Accept it only if both text strings are exact, no additional text is present, and no WhatsApp or Signal logo was invented. If the first result is unusable, retry once with the same prompt plus the sentence `Correct the text exactly and remove every unrequested mark.` If the second result is still unusable, delete the failing social-card test from Step 1 and ship without `og:image` or `twitter:image`.

- [ ] **Step 5: Save and wire the valid social card**

When the image passes inspection, save it as `website/public/og.png` and update the existing metadata blocks inside `generateMetadata()` in `website/app/layout.tsx`:

```ts
  openGraph: {
    title: siteConfig.title,
    description: siteConfig.description,
    type: "website",
    url: origin,
    images: [
      {
        url: `${origin}/og.png`,
        width: 1200,
        height: 630,
        alt: "Bring your WhatsApp stickers to Signal with StickerPort.",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: siteConfig.title,
    description: siteConfig.description,
    images: [`${origin}/og.png`],
  },
```

- [ ] **Step 6: Run the complete contract**

Run:

```bash
npm test
```

Working directory: `website/`

Expected: all tests pass with the valid social card, or all non-social-card tests pass after the explicit two-attempt fallback.

- [ ] **Step 7: Commit the metadata result**

If the card passed, run:

```bash
git add website/app/layout.tsx website/public/og.png website/tests/rendered-html.test.mjs
git commit -m "feat: add StickerPort social preview"
```

If the card was omitted after two failed validations, do not create an empty commit.

### Task 6: Verify the Production Site and Direct DMG Response

**Files:**
- Verify: `website/**`

**Interfaces:**
- Consumes: complete landing-page source and GitHub release URL
- Produces: passing lint, production build, SSR contract, and confirmed direct-download response

- [ ] **Step 1: Run lint**

Run:

```bash
npm run lint
```

Working directory: `website/`

Expected: ESLint exits with status `0`.

- [ ] **Step 2: Run the deployment build**

Run:

```bash
npm run build
```

Working directory: `website/`

Expected: Vinext produces `website/dist/server/index.js` with exit status `0`.

- [ ] **Step 3: Run the full SSR contract against the production build**

Run:

```bash
node --test tests/rendered-html.test.mjs
```

Working directory: `website/`

Expected: all tests pass without rebuilding.

- [ ] **Step 4: Verify the direct DMG URL resolves to a downloadable asset**

Run:

```bash
curl -sIL -o /dev/null -w '%{http_code} %{url_effective} %{content_type}\n' https://github.com/megabyte0x/stickerport/releases/download/v0.1.0/StickerPort-0.1.0.dmg
```

Expected: status `200`, an effective GitHub release-assets URL, and content type `application/x-apple-diskimage` or `application/octet-stream`.

- [ ] **Step 5: Verify attachment headers and filename**

Run:

```bash
curl -sIL https://github.com/megabyte0x/stickerport/releases/download/v0.1.0/StickerPort-0.1.0.dmg | rg -i 'content-disposition:.*StickerPort-0.1.0.dmg|content-type: application/(x-apple-diskimage|octet-stream)'
```

Expected: at least one content-disposition or accepted content-type header confirming the direct asset response.

- [ ] **Step 6: Confirm only intended files changed**

Run from the worktree root:

```bash
git status --short
git diff --stat HEAD
```

Expected: no Swift/Xcode source modifications and no untracked build output because `node_modules`, `dist`, `.vinext`, and `.wrangler` are ignored.

### Task 7: Configure Sites Hosting and Publish the Validated Version

**Files:**
- Modify: `website/.openai/hosting.json`
- Verify: `website/dist/**`
- Create outside repository: `/tmp/stickerport-site-version.tgz`

**Interfaces:**
- Consumes: successful Task 6 build and Sites connector tools discovered at execution time
- Produces: persisted Sites project ID, committed validated source, saved site version, deployment status `succeeded`, and deployed URL

- [ ] **Step 1: Create the Sites project once**

Call the Sites `create_site` connector with the requested site name `StickerPort` and slug `stickerport`. If the connector reports a slug conflict, stop and report it; do not invent another slug. Retain the returned `project_id` and source repository write credential for this publication sequence.

- [ ] **Step 2: Persist the returned project ID**

Use `apply_patch` to add a `project_id` string property whose value is exactly the connector result. Keep `"d1": null` and `"r2": null` unchanged. Validate the edited file with `jq -e '.project_id | type == "string" and length > 0' website/.openai/hosting.json` before continuing.

- [ ] **Step 3: Rebuild and retest the exact source that will be published**

Run:

```bash
npm run build
node --test tests/rendered-html.test.mjs
```

Working directory: `website/`

Expected: build and all tests pass after hosting metadata is added.

- [ ] **Step 4: Commit the hosting metadata**

Run from the worktree root:

```bash
git add website/.openai/hosting.json
git commit -m "chore: configure StickerPort site hosting"
git rev-parse HEAD
```

Expected: a commit SHA representing the exact validated source.

- [ ] **Step 5: Push the committed source with the temporary Sites credential**

Use the credential returned by `create_site` as a per-command HTTP authorization header, never in a remote URL or Git config. Push branch `codex/stickerport-site` and use the pushed branch-head SHA as `commit_sha` for the saved version.

- [ ] **Step 6: Package the validated build**

Run from the worktree root:

```bash
/Users/megabyte0x/.codex/plugins/cache/openai-bundled/sites/0.1.30/scripts/package-site.sh website /tmp/stickerport-site-version.tgz
tar -tzf /tmp/stickerport-site-version.tgz | rg '^dist/server/index.js$|^dist/.openai/hosting.json$'
```

Expected: the archive contains both required files.

- [ ] **Step 7: Save one Sites version**

Call the Sites version-saving connector once with the Task 7 Step 4 `commit_sha` and `/tmp/stickerport-site-version.tgz`. Retain the returned version identifier.

- [ ] **Step 8: Deploy with the safest available access level**

Use `deploy_private_site_version` when available. If the connector only offers shared or public deployment, request explicit approval naming that exact access level before calling `deploy_site_version`.

- [ ] **Step 9: Poll the deployment directly**

Call `get_deployment_status` until it reports `status: "succeeded"` or a terminal failure. Do not rediscover the project or create another site while polling.

- [ ] **Step 10: Open and hand off the deployed site**

After success, call `open_in_codex` with the exact deployed URL and no explicit thread ID. Return the URL, the fact that the download button points directly to the verified GitHub DMG, and the deployed access level.

## Final Verification Checklist

- [ ] Work occurred only in `.worktrees/stickerport-site` on `codex/stickerport-site` after the plan commit.
- [ ] Existing Swift/Xcode source is unchanged.
- [ ] The site is one route and has one primary CTA.
- [ ] The exact headline and direct DMG URL are present in production SSR HTML.
- [ ] The page CSS locks both axes and uses `100svh` plus `100dvh`.
- [ ] Small-width and short-height media queries reduce nonessential content instead of enabling scroll.
- [ ] Button press and keyboard focus feedback are present.
- [ ] Reduced motion, reduced transparency, increased contrast, and dark appearance are supported.
- [ ] Starter skeleton, temporary metadata, loading dependency, and generic SVG assets are gone.
- [ ] No trackers, forms, auth, persistence, direct Signal automation, or unsupported claims were introduced.
- [ ] Lint, build, SSR tests, DMG response validation, package validation, and deployment all succeed.
