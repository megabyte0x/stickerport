# StickerPort SEO Strategy

Last updated: 2026-07-20

## Executive summary

StickerPort should own a narrow, high-intent problem rather than compete for the broad phrase “sticker maker.” The defensible search position is:

> The local, read-only macOS workflow for moving the WhatsApp Desktop stickers already on a Mac into Signal Desktop's official sticker creator.

The sampled search landscape is split between Signal's official creator documentation, mobile-first multi-platform sticker apps, public sticker directories, online sticker makers, and technical converter projects. None of those surfaces explains StickerPort's exact combination of installed WhatsApp Desktop discovery, explicit folder access, read-only handling, local export, and supported Signal handoff.

The initial implementation therefore creates a six-page crawlable cluster around transfer intent, requirements, privacy, frequently asked questions, and project evidence. The next six months should deepen that cluster with troubleshooting and comparison content only when claims can be kept current.

The companion [GEO analysis](GEO-ANALYSIS.md) scores the implemented AI-search
foundation at 83/100 and records crawler, citation-passage, entity, brand
mention, licensing, SSR, and social-card evidence.

## Discovery and assumptions

### Product

- Free, open-source macOS utility.
- Current verified release: 0.2.1.
- Requires macOS 15 or later; universal Apple silicon and Intel build.
- Reads an explicitly selected WhatsApp Desktop shared container.
- Opens supported SQLite sources read-only and query-only.
- Exports compatible static WebP stickers into an ordinary folder.
- Leaves the final upload and installation to Signal Desktop's official creator.

### Primary audience

1. Privacy-conscious people moving from WhatsApp to Signal.
2. Mac users with personal sticker packs or Favorites they do not want to recreate.
3. Signal users searching for the correct file requirements and upload workflow.
4. Technical users who want an inspectable alternative to credential-based converters or online upload tools.

### Business goal

Increase qualified downloads of StickerPort from people who already have transfer intent. There is no paid plan or sales funnel, so success is measured by useful organic visits, guide completion signals, download clicks, successful indexing, and trusted references from privacy or Signal communities.

### Constraints

- No SEO budget or publishing team was specified; this plan assumes one maintainer.
- DataForSEO, Ahrefs, Semrush, Moz, and Search Console query data were unavailable.
- Google PageSpeed Insights quota was exhausted during baseline collection, so Core Web Vitals need a later field-data baseline.
- The StickerPort Mixpanel project exists in the EU region, but the available analytics connector was pointed at the US region and could not query the project. Production event totals are therefore not included as a confirmed baseline.
- Competitor authority levels in this plan are qualitative proxies, not third-party domain-authority scores.

## Current-site assessment

### Before this implementation

- One crawlable product route at `/`.
- Good unique title, meta description, one H1, Open Graph image, and server-rendered product copy.
- No canonical link.
- No structured data.
- `/sitemap.xml` returned 404.
- `robots.txt` contained Cloudflare content-signal language but no sitemap declaration.
- No dedicated guide, privacy, requirements, FAQ, or about route.
- Internal links pointed only to the source repository.
- Production CSS and JavaScript assets were healthy after the existing Cloudflare `_routes.json` fix.
- A sampled `site:stickerport.megabyte.sh` search did not confirm an indexed StickerPort page.

### Implemented foundation

- Six canonical URLs in a static XML sitemap.
- Conventional robots directives plus explicit search/AI discovery access.
- Organization, WebSite, and SoftwareApplication JSON-LD on the entire site.
- HowTo, FAQPage, TechArticle, WebPage, AboutPage, and BreadcrumbList JSON-LD on relevant routes.
- A high-intent transfer guide, requirements reference, privacy page, FAQ, and about page.
- Crawlable internal navigation between the homepage and the resource cluster.
- Fixed production-domain metadata instead of request-host canonicals.
- `llms.txt` with quotable product facts and authoritative page links.
- Explicit GPTBot, OAI-SearchBot, ChatGPT-User, ClaudeBot, and PerplexityBot
  access.
- Three source-backed direct-answer passages sized for passage-level citation.
- A named maintainer entity, visible reviewed dates, and Person schema.
- Explicit Open Graph and Twitter image dimensions, MIME type, and alt text.
- Optional Google and Bing verification values through environment variables.
- Page-view and download-click properties for page type, path, referring host, and traffic class without storing full referrer URLs.

## Search positioning

### Primary promise

Move WhatsApp stickers to Signal on a Mac without uploading the source collection or changing WhatsApp data.

### Differentiators to repeat consistently

- Installed WhatsApp Desktop packs and Favorites, not only loose image files.
- Local extraction and export.
- Explicit folder selection instead of broad Full Disk Access.
- Read-only and fail-closed database handling.
- No WhatsApp login or Signal credentials.
- Official Signal Desktop creator for the final upload.
- Open source with release checksums and a visible release pipeline.

### Avoid

- “Automatic Signal import” or “one-click transfer” claims.
- Claims that all WhatsApp versions or animated stickers are supported.
- Broad “best sticker maker” positioning that does not match the product.
- Comparison claims that cannot be rechecked at least quarterly.
- Keyword stuffing around WhatsApp, Signal, or sticker-brand names.

## Keyword and intent map

Volume and difficulty are unverified. Prioritize by product fit and intent until Search Console supplies impression data.

| Cluster | Search intent | Primary target page | Priority |
|---|---|---|---|
| transfer WhatsApp stickers to Signal | Complete the migration | `/guides/transfer-whatsapp-stickers-to-signal` | P0 |
| move/import WhatsApp stickers into Signal | Find a working method | `/guides/transfer-whatsapp-stickers-to-signal` | P0 |
| WhatsApp sticker converter for Signal Mac | Evaluate a tool | `/` | P0 |
| Signal sticker requirements | Validate files before upload | `/signal-sticker-requirements` | P0 |
| private/local WhatsApp sticker converter | Evaluate safety | `/privacy` | P1 |
| WhatsApp Favorites stickers on Mac | Find a specific source | Future troubleshooting guide | P1 |
| Signal sticker 300 KB / 512 × 512 / 200 limit | Solve a rejected upload | `/signal-sticker-requirements` | P1 |
| StickerPort safe / open source / review | Trust evaluation | `/privacy` and `/about` | P1 |
| SigStick alternative for Mac | Compare local versus mobile/community workflows | Future verified comparison | P2 |
| sticker-convert alternative for Mac | Compare simple GUI versus technical converter | Future verified comparison | P2 |

## Content pillars

### 1. Transfer workflow

Own the exact journey from installed WhatsApp Desktop data to Signal Desktop's creator. Pages should answer prerequisites, the seven steps, failure cases, and what remains manual.

### 2. Compatibility and troubleshooting

Publish concise references for file dimensions, file size, pack limits, macOS/WhatsApp compatibility, database changes, inactive-source errors, and skipped stickers.

### 3. Privacy and trust

Explain folder access, read-only database flags, fail-closed validation, output boundaries, website analytics, source code, release verification, and independent-product disclaimers.

### 4. Alternatives and migration choices

Only after the foundation is indexed, publish factual comparisons covering mobile/community apps, technical converters, and manual workflows. State who each option is for instead of declaring universal winners.

## E-E-A-T plan

### Experience

- Show the exact application and Signal handoff workflow.
- Maintain troubleshooting notes based on reproducible app behavior.
- Add screenshots or short clips to future guides when they materially clarify a step.

### Expertise

- Link technical claims to the open-source implementation and tests.
- Date compatibility statements and state the observed WhatsApp Desktop version when relevant.
- Link Signal format claims to Signal's official documentation.

### Authoritativeness

- Keep a stable maintainer identity linked to the public GitHub profile.
- Publish signed/notarized release evidence, checksums, changelog entries, and source history.
- Seek relevant links from Signal/privacy communities through useful documentation, not paid links.

### Trust

- Keep “not affiliated” language visible.
- Avoid credentials, private APIs, and hidden data access.
- Add a lightweight security/contact policy in Phase 2.
- Correct stale compatibility pages quickly after WhatsApp or Signal changes.

## Technical foundation

### Indexing and canonicalization

- Production canonical origin: `https://stickerport.megabyte.sh`.
- Include only unique, useful 200-status pages in the sitemap.
- Exclude the `/download` redirect from the sitemap.
- Keep Cloudflare Pages `/assets/*` excluded from the Vinext Worker route.
- Redirect alternate hostnames to the canonical domain at the platform layer if any appear.

### Structured data

| Page type | Schema |
|---|---|
| Homepage | Organization, WebSite, SoftwareApplication |
| Transfer guide | HowTo, BreadcrumbList |
| Requirements reference | TechArticle, BreadcrumbList |
| FAQ | FAQPage, BreadcrumbList |
| Privacy | WebPage, BreadcrumbList |
| About | AboutPage, BreadcrumbList |

Do not add ratings, reviews, or usage counts unless they are sourced and visible on the page.

### Core Web Vitals targets

- LCP: under 2.5 seconds at the 75th percentile.
- INP: under 200 milliseconds at the 75th percentile.
- CLS: under 0.1 at the 75th percentile.
- Keep content pages primarily server-rendered and avoid adding client JavaScript for decorative effects.
- Recheck the homepage video as the main performance risk; preserve `preload="metadata"` and avoid autoplaying additional media on content pages.

### AI search readiness

- Keep critical facts in server-rendered prose, not only video or client UI.
- Use self-contained headings and answer-first paragraphs.
- Maintain `llms.txt`, structured data, canonical pages, dates, and source links.
- Prefer explicit boundaries such as “does not upload” and “static stickers only” because they are easy to quote accurately.

### Mobile-first requirements

- All resources must remain readable without horizontal page overflow.
- Tables may scroll within their own container.
- Sticky navigation must not cover the H1 or keyboard focus.
- Primary content must not be hidden at mobile breakpoints.

## Measurement plan

### Events

| Event | Required properties | Purpose |
|---|---|---|
| `Page Viewed` | `page_path`, `page_type`, `traffic_source`, `referrer_host` | Measure landing and content demand |
| `Download Clicked` | `placement`, `page_path`, `page_type`, `traffic_source`, `referrer_host` | Attribute qualified download intent |

No full referrer URL, query string, IP geolocation, session recording, autocapture, or persistent visitor storage should be collected.

### KPI targets

These targets are starting hypotheses for a new niche site and should be reset after 60 days of Search Console and Mixpanel evidence.

| Metric | Baseline | 3 Month | 6 Month | 12 Month |
|---|---:|---:|---:|---:|
| Organic sessions/month | Unconfirmed | 150 | 600 | 1,500 |
| Keywords in top 20 | 0 confirmed | 5 | 12 | 25 |
| Keywords in top 10 | 0 confirmed | 1 | 4 | 10 |
| Domain Authority | Not tool-measured | Record baseline | Baseline +3 | Baseline +7 |
| Referring domains | Unconfirmed | 5 | 15 | 35 |
| Indexed useful pages | 0 confirmed; 6 submitted | 6 | 10 | 20 |
| Core Web Vitals | Field baseline unavailable | All core templates pass | Maintain pass | Maintain pass |
| Organic visit → download click | Unconfirmed | 8% | 10% | 12% |

## Resources and cadence

- One maintainer: one useful article or substantial update every two weeks.
- Technical SEO: two to four hours monthly for crawl, metadata, schema, and production checks.
- Measurement: one hour monthly after Search Console and EU-region Mixpanel access are connected.
- Outreach: two hours per published guide for relevant, non-spammy community distribution.
- No paid link acquisition.

## Dependencies

- Verify the domain in Google Search Console and Bing Webmaster Tools.
- Submit `sitemap.xml` after ownership verification.
- Connect the analytics tooling to Mixpanel's EU MCP endpoint or use the Mixpanel UI for baselines.
- Establish a field Core Web Vitals baseline when PageSpeed quota or Search Console data is available.
- Recheck Signal and WhatsApp compatibility before every requirements or comparison update.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Search volume is smaller than expected | Expand into adjacent troubleshooting intent, not unrelated broad sticker creation |
| WhatsApp schema changes | Date compatibility pages, fail closed in the product, publish update notes quickly |
| Signal requirements change | Link to the official source and schedule quarterly review |
| Brand query collision with unrelated “StickerPort” uses | Consistently use “StickerPort for macOS” and the WhatsApp-to-Signal descriptor |
| Thin comparison pages damage trust | Publish only after a documented, current feature review |
| Homepage video hurts performance | Keep one optimized clip, metadata preload, and no additional autoplay media |
| Analytics data remains inaccessible | Fix EU-region connector access and retain privacy-preserving local event design |

## Success criteria

- All six implemented URLs return 200, self-canonicalize, and appear in the sitemap.
- Structured data describes only visible and verifiable claims.
- The transfer guide begins earning impressions for migration-intent queries.
- Organic downloads can be attributed without collecting full URLs or persistent identity.
- New content follows the architecture and evidence rules in this strategy.

## Research references

- [Signal sticker documentation](https://support.signal.org/hc/en-us/articles/360031836512-Stickers)
- [SigStick](https://www.sigstick.com/)
- [sticker-convert](https://github.com/laggykiller/sticker-convert)
- [SignalStickers](https://signalstickers.org/)
- [Signal Sticker Maker](https://signalstickermaker.com/)
