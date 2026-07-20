# StickerPort GEO Analysis

Assessment date: 2026-07-20

Scope: AI Overviews, ChatGPT web search, Perplexity, Bing Copilot, AI crawler accessibility, passage-level citability, entity signals, `llms.txt`, and social-card readiness.

## Executive assessment

**GEO readiness score: 83/100**

StickerPort now has a strong on-site GEO foundation: important facts are server-rendered, three high-intent pages begin with self-contained answer passages, official Signal requirements are attributed to a primary source, AI search crawlers are explicitly allowed, `llms.txt` gives machines a concise site map and citation boundaries, and JSON-LD connects the product, project, maintainer, website, and content.

The largest remaining weakness is off-site authority. A sampled exact-domain search found no indexed mentions of `stickerport.megabyte.sh` on Reddit, YouTube, LinkedIn, or Wikipedia. The public GitHub repository is the only verified external entity surface, and its repository homepage and topics were unset at assessment time. Unrelated uses of “StickerPort” also appear in brand search, increasing the need for consistent “StickerPort for macOS” naming and third-party mentions.

## Score breakdown

| Category | Weight | Score | Evidence |
|---|---:|---:|---|
| Passage-level citability | 25 | 23 | Three sourced, self-contained answer blocks of 135–143 words |
| Structural readability | 20 | 19 | SSR headings, questions, steps, lists, tables, FAQ, and internal navigation |
| Multi-modal content | 15 | 12 | Homepage tutorial video, product imagery, and a verified 1200×630 social card |
| Authority and brand signals | 20 | 10 | Visible maintainer, dates, source links, Person schema; little verified off-site presence |
| Technical accessibility | 20 | 19 | SSR, crawler access, `llms.txt`, canonical/schema coverage; no RSL policy |
| **Total** | **100** | **83** | |

## Platform breakdown

| Platform | Readiness | Rationale |
|---|---:|---|
| Google AI Overviews | 87/100 | Strong traditional SEO, canonical SSR pages, source-backed answer passages, HowTo/TechArticle/FAQ structure |
| ChatGPT web search | 84/100 | OAI crawlers explicitly allowed, `llms.txt`, named entities, concise product boundaries, public source repository |
| Bing Copilot | 82/100 | Crawlable SSR and sitemap; Bing verification and submission still require owner setup |
| Perplexity | 75/100 | Extractable passages and primary citations are strong, but no verified Reddit or Wikipedia validation |

These scores measure readiness, not confirmed citation frequency. Actual visibility must be measured after deployment and indexing.

## AI crawler access

The implemented `robots.txt` explicitly allows the core search-oriented agents and retains a general allow rule.

| Crawler | Status | Rule |
|---|---|---|
| OAI-SearchBot | Explicitly allowed | `User-agent: OAI-SearchBot` |
| GPTBot | Explicitly allowed | `User-agent: GPTBot` |
| ChatGPT-User | Explicitly allowed | `User-agent: ChatGPT-User` |
| ClaudeBot | Explicitly allowed | `User-agent: ClaudeBot` |
| PerplexityBot | Explicitly allowed | `User-agent: PerplexityBot` |
| Googlebot / Bingbot | Allowed | Covered by `User-agent: *` |
| CCBot and training-oriented crawlers | Allowed by wildcard | No explicit training policy selected |

### Licensing status

RSL 1.0 is **not implemented**. The repository does not currently define a root content license or an AI-use policy, so inventing machine-readable licensing terms would exceed the available authorization. Decide the desired search, inference, and training permissions before adding RSL or crawler-specific training restrictions.

## `llms.txt` status

**Status: present and compliant with the implemented site scope.**

The file includes:

- a one-sentence product definition;
- canonical site, version, platform, maintainer, and reviewed date;
- seven precise product and safety facts;
- Markdown links with descriptions for every primary page;
- an authoritative Signal reference;
- citation guidance that distinguishes StickerPort's local export from Signal's final upload;
- the current animated-sticker limitation.

Keep the version, reviewed date, and compatibility claims synchronized with each release.

## Brand mention analysis

### Verified owned surfaces

- Production website: `https://stickerport.megabyte.sh`
- GitHub repository: `https://github.com/megabyte0x/stickerport`
- Maintainer profile: `https://github.com/megabyte0x`

The GitHub API confirmed a public repository whose description says “Local-only macOS bridge from WhatsApp Desktop stickers to Signal Desktop.” At assessment time it had no homepage URL, no repository topics, and no stars or forks.

### Sampled external presence

| Surface | Verified exact-domain mention |
|---|---|
| Wikipedia | None found |
| Reddit | None found |
| YouTube | None found |
| LinkedIn | None found |
| Broad web search | No owned exact-domain result confirmed |

This is a discovery snapshot, not proof that no mention exists anywhere. Search also surfaced unrelated “StickerPort” uses, so entity disambiguation matters.

### Recommended entity actions

1. Set the GitHub repository homepage to `https://stickerport.megabyte.sh`.
2. Add accurate GitHub topics such as `macos`, `whatsapp-stickers`, `signal-stickers`, `swift`, and `privacy`.
3. Publish one maintainer-authored launch walkthrough with the canonical URL.
4. Share the guide in relevant communities only where their self-promotion rules permit it.
5. Create a short video demonstration whose title and description use “StickerPort for macOS” and link to the transfer guide.

Do not create Wikipedia content for a new project without independent notability and reliable third-party sources.

## Passage-level citability

### Implemented answer blocks

| Page | Question heading | Passage length | Source treatment |
|---|---|---:|---|
| Transfer guide | How do you transfer WhatsApp stickers to Signal on a Mac? | 138 words | Signal documentation plus StickerPort source |
| Requirements | What files does Signal accept for a custom sticker pack? | 143 words | Official Signal documentation and review date |
| Privacy | Does StickerPort upload or change your WhatsApp stickers? | 135 words | Public source, tests, and release scripts |

Each passage:

- answers the query immediately;
- can be extracted without surrounding page context;
- contains concrete constraints and product boundaries;
- is followed by a visible evidence line;
- appears in server-rendered HTML;
- sits before the longer supporting sections.

### Remaining citability opportunities

- Add one sourced answer block to the FAQ covering the macOS/architecture requirement.
- Publish original, anonymized compatibility data only after enough real issues exist.
- Add measured workflow timing only after a reproducible study; do not invent “minutes saved” claims.
- Add release-security facts with verifiable notarization and checksum evidence.

## Structural readability

The implemented resource pages use:

- one H1 per route;
- question-shaped H2 headings for direct answers;
- H2/H3 hierarchy;
- ordered steps for the transfer;
- a requirements comparison table;
- short troubleshooting cards;
- a structured FAQ;
- visible maintainer and reviewed-date information;
- contextual primary-source links.

The site avoids large client-only content regions. Core answers remain understandable without the homepage video.

## Multi-modal readiness

### Present

- 1200×630 PNG social card, 373,430 bytes.
- Explicit Open Graph and Twitter image URL, width, height, MIME type, and alt text.
- `summary_large_image` Twitter card.
- Homepage tutorial video with text fallback and a visible step summary.
- App and sticker visuals that reinforce the product workflow.

### Next

- Add one annotated screenshot to the transfer guide for the macOS folder picker.
- Add one Signal creator screenshot or short clip with a text caption.
- Keep all critical instructions in text so media remains supplementary.

## Server-side rendering check

**Status: passes.**

Vinext's server worker renders:

- unique titles and descriptions;
- canonical links;
- social metadata;
- global and page-specific JSON-LD;
- headings, answer passages, steps, tables, FAQ content, sources, dates, and author information.

Automated tests fetch the built worker directly and assert the rendered HTML. AI crawlers do not need to execute client JavaScript to understand the product or primary guides.

## Schema assessment

### Implemented

- Organization
- Person
- WebSite
- SoftwareApplication
- HowTo
- TechArticle
- FAQPage
- WebPage
- AboutPage
- BreadcrumbList

The graph uses stable fragment identifiers for the organization, maintainer, website, and software application. Articles and product behavior point to the named maintainer and project publisher.

### Do not add yet

- AggregateRating or Review without visible sourced reviews.
- User counts, download counts, or performance claims without measured evidence.
- `sameAs` links for social accounts that do not exist.
- Awards, credentials, or affiliations that cannot be verified.

## Top five highest-impact next changes

1. Deploy the current implementation, then submit the sitemap to Google and Bing.
2. Connect the GitHub repository's homepage and topics to the same product entity.
3. Earn the first independent, relevant mention from a privacy, macOS, Signal, or open-source community.
4. Publish a captioned video walkthrough and link it to the canonical transfer guide.
5. Choose and publish a content/AI licensing policy before implementing RSL or training-crawler restrictions.

## Verification requirements

Before declaring production GEO readiness:

1. All six sitemap URLs return 200 on the canonical host.
2. `robots.txt` exposes the five explicit AI crawler groups.
3. `llms.txt` returns the current structured guidance.
4. The three direct-answer passages render in HTML at 134–167 words.
5. Person and SoftwareApplication JSON-LD render without unsupported claims.
6. Open Graph and Twitter tags point to the 1200×630 PNG and include alt text.
7. `/download` still redirects to the verified release asset.
8. Search Console, Bing, and AI visibility baselines are recorded after indexing.

## Sources

- [Signal sticker documentation](https://support.signal.org/hc/en-us/articles/360031836512-Stickers)
- [StickerPort source repository](https://github.com/megabyte0x/stickerport)
- [StickerPort production site](https://stickerport.megabyte.sh/)
