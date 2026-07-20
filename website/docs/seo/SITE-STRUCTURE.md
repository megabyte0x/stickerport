# StickerPort Site Structure and Information Architecture

Last updated: 2026-07-20

## Architecture principles

- Keep the site small and task-oriented.
- Give every indexable URL a unique job.
- Place the transfer guide at the center of the content graph.
- Use the homepage for product evaluation, not every possible answer.
- Put changeable external requirements in a dated reference page.
- Keep download redirects, assets, and utility endpoints out of the sitemap.

## Implemented hierarchy

```text
/
├── /guides/transfer-whatsapp-stickers-to-signal
├── /signal-sticker-requirements
├── /privacy
├── /faq
├── /about
└── /download                         307 utility redirect, not in sitemap
```

## Planned hierarchy

Add only when the content meets the quality gate.

```text
/
├── /guides
│   ├── /transfer-whatsapp-stickers-to-signal
│   ├── /where-whatsapp-stores-stickers-on-mac
│   ├── /whatsapp-favorites-to-signal
│   ├── /why-quit-whatsapp-before-export
│   ├── /fix-signal-sticker-size-format-errors
│   └── /verify-stickerport-download
├── /compare
│   ├── /local-app-vs-online-sticker-converter
│   ├── /stickerport-vs-sticker-convert
│   └── /stickerport-vs-sigstick
├── /compatibility
│   └── /whatsapp-desktop
├── /signal-sticker-requirements
├── /privacy
├── /security
├── /faq
└── /about
```

Do not create empty `/guides`, `/compare`, or `/compatibility` hubs until at least three child pages exist or the hub provides standalone value.

## Page roles

| URL | Primary user question | Primary keyword cluster | Main conversion |
|---|---|---|---|
| `/` | Is there a trustworthy Mac tool for this? | WhatsApp sticker converter Signal Mac | Download |
| `/guides/transfer-whatsapp-stickers-to-signal` | How do I complete the transfer? | transfer/move/import WhatsApp stickers to Signal | Download |
| `/signal-sticker-requirements` | Why will Signal accept or reject these files? | Signal sticker requirements | Guide/download |
| `/privacy` | What does the app read, write, or upload? | private/local sticker converter | Source/download |
| `/faq` | Does it support my situation? | StickerPort and transfer questions | Guide/download |
| `/about` | Who maintains this and what evidence exists? | StickerPort project/open source | Source/releases |

## Internal-linking model

```text
Homepage
  ├── Transfer guide ── Requirements
  │        ├── Privacy
  │        └── FAQ
  ├── Requirements ─── Transfer guide
  ├── Privacy ───────── Source + About
  ├── FAQ ───────────── Guide + Privacy + Source
  └── About ─────────── Source + Releases
```

### Linking rules

- Every guide links to the transfer guide or requirements reference when relevant.
- Every comparison links to a neutral requirements or privacy source, not only a download CTA.
- Use descriptive anchors such as “Signal sticker requirements,” not “click here.”
- Do not add sitewide links to every future article; keep global navigation stable.
- Add related-content blocks based on real topic relationships, not publication date.

## Sitemap quality gates

An URL may enter `sitemap.xml` only if it:

- returns 200 without authentication;
- has a unique title, description, H1, and self-canonical;
- contains substantive server-rendered content;
- is not a redirect, download endpoint, duplicate, preview, or parameter variant;
- is linked from at least one other indexable page;
- has no `noindex` directive;
- is accurate and maintained.

Remove a URL from the sitemap before redirecting, consolidating, or retiring it.

## Canonical and URL conventions

- HTTPS only.
- Lowercase paths.
- Hyphenated descriptive slugs.
- No trailing slash in internal links except the root.
- No dates in evergreen guide URLs.
- No query parameters for indexable content.
- Canonical origin is always `https://stickerport.megabyte.sh`.

## Structured-data map

```text
Root layout
  └── Organization + Person + WebSite + SoftwareApplication

Transfer guide
  └── HowTo + BreadcrumbList

Requirements
  └── TechArticle + BreadcrumbList

FAQ
  └── FAQPage + BreadcrumbList

Privacy
  └── WebPage + BreadcrumbList

About
  └── AboutPage + BreadcrumbList
```

## User journeys

### Migration-ready user

Search result → transfer guide → download → app workflow → Signal official creator.

### Safety-conscious user

Search result or homepage → privacy → source/about → download.

### Rejected-file user

Search result → requirements → troubleshooting guide → transfer guide/download.

### Technical evaluator

Homepage → about/privacy → GitHub source and releases → download or build from source.
