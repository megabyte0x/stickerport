# StickerPort SEO Implementation Roadmap

Last updated: 2026-07-20

## Phase 1 — Foundation, weeks 1–4

### Completed in the repository

- Fixed canonical origin and self-referencing canonical metadata.
- Added index/follow and rich-preview robot metadata.
- Added Organization, WebSite, and SoftwareApplication JSON-LD.
- Added page-level HowTo, FAQPage, TechArticle, WebPage, AboutPage, and breadcrumbs.
- Added a named Person entity and visible maintainer/reviewed-date signals.
- Added three source-backed, self-contained answer passages sized for AI citation.
- Explicitly allowed GPTBot, OAI-SearchBot, ChatGPT-User, ClaudeBot, and PerplexityBot.
- Verified a 1200×630 Twitter/OG image with explicit MIME type, dimensions, and alt text.
- Added `/robots.txt`, `/sitemap.xml`, and `/llms.txt`.
- Added five crawlable supporting pages around transfer, requirements, privacy, FAQ, and project evidence.
- Added internal links from the homepage and a shared resource navigation.
- Added optional Google and Bing site-verification environment variables.
- Reworked analytics into `Page Viewed` and `Download Clicked` events with page and traffic attribution.
- Preserved privacy controls: no autocapture, session recording, persistent identity, IP geolocation, full referrer URL, or query string.
- Added automated route, metadata, schema, sitemap, discovery-file, and Cloudflare-output tests.

### External completion items

- Verify `stickerport.megabyte.sh` in Google Search Console.
- Verify the domain in Bing Webmaster Tools.
- Submit `https://stickerport.megabyte.sh/sitemap.xml` to both.
- Point the analytics connector at Mixpanel's EU endpoint and record the first baseline.
- Record field Core Web Vitals when Search Console or PageSpeed data becomes available.

### Phase 1 exit criteria

- Six useful sitemap URLs are deployed and return 200.
- Production canonicals and structured data match the deployed host.
- Search engines accept the sitemap without errors.
- Baseline impressions, indexed pages, and download-click conversion are recorded.

## Phase 2 — Expansion, weeks 5–12

### Content

- Publish the first six troubleshooting and how-to articles in the content calendar.
- Add a visible “last reviewed” date to every compatibility-sensitive page.
- Add screenshots only where they clarify folder selection or Signal's creator.
- Add a dedicated security/contact policy linked from privacy and about pages.

### Internal linking

- Add contextual links from each new troubleshooting page to the transfer guide and requirements reference.
- Add “related guides” blocks only after at least three real guides exist.
- Link the app README to the highest-value web guide where appropriate.

### Measurement

- Build a monthly organic-to-download report.
- Segment landing, guide, reference, trust, FAQ, and company page types.
- Use Search Console query data to replace assumed keyword priorities.

### Phase 2 exit criteria

- At least ten useful indexed pages.
- Five relevant keywords in the top 20 or a documented pivot based on real impressions.
- Organic visit-to-download baseline and first optimization experiment completed.

## Phase 3 — Scale, weeks 13–24

### Content and GEO

- Publish comparison pages only after current capability reviews.
- Add a versioned compatibility hub for WhatsApp Desktop changes.
- Publish a sourced release-security guide.
- Add concise answer blocks and comparison tables that search and AI systems can parse.

### Authority

- Share new guides with relevant Signal, macOS, privacy, and open-source communities where self-promotion is allowed.
- Seek links through useful technical documentation, issue answers, and community references.
- Avoid paid, exchanged, or bulk directory links.

### Performance

- Review field Core Web Vitals by template.
- Optimize or replace the homepage video if it becomes the LCP or bandwidth bottleneck.
- Keep content routes mostly server components.

### Phase 3 exit criteria

- Twelve keywords in the top 20 and four in the top 10, or revised targets based on actual market size.
- Fifteen relevant referring domains.
- All core templates pass field Core Web Vitals.

## Phase 4 — Authority, months 7–12

### Original evidence

- Publish an anonymized compatibility or troubleshooting report based on real issue patterns.
- Publish technical notes about safe read-only import design.
- Maintain a public compatibility matrix with review dates.

### Reputation

- Earn references from open-source, privacy, macOS, or migration resources.
- Keep maintainer, source, release, and security information current.
- Monitor brand-result confusion with unrelated StickerPort uses.

### Continuous optimization

- Refresh pages with impressions but weak click-through rates.
- Improve pages with qualified traffic but weak download conversion.
- Consolidate overlapping pages rather than allowing cannibalization.
- Remove stale comparison content when it cannot be maintained.

### Phase 4 exit criteria

- Twenty-five keywords in the top 20 and ten in the top 10, subject to market-size reset.
- Thirty-five relevant referring domains.
- Organic traffic contributes a stable, measurable share of monthly downloads.

## Ownership and time

| Workstream | Owner | Time assumption |
|---|---|---:|
| Technical SEO and deployment checks | Maintainer | 2–4 hours/month |
| Content research and writing | Maintainer | 6–10 hours/article |
| Search and analytics review | Maintainer | 1–2 hours/month |
| Community distribution | Maintainer | 2 hours/article |
| Product compatibility verification | Maintainer | Included with releases |

## Verification commands

From `website/`:

```bash
npm test
npm run lint
npm run verify:production
```

After deployment, separately verify:

- every sitemap URL returns 200;
- `/robots.txt`, `/sitemap.xml`, and `/llms.txt` return the expected body and content type;
- canonical links use `https://stickerport.megabyte.sh`;
- the homepage and guide contain valid JSON-LD;
- `/download` still redirects to the stable verified GitHub DMG;
- CSS/JS assets continue to bypass the Vinext Worker and return correct MIME types.
