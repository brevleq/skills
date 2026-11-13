---
name: internal-linking
description: Adds internal links for SEO when a new article is written or published on a site, following Neil Patel's guide to internal links. Finds related existing pages (in the repository, a sitemap or the live site), links the new article to at least 5 older articles with descriptive anchor text placed in the body where topics overlap, and proposes updates to older articles so they link back to the new one. Follows the site's own link format and content conventions. Use when the user asks to write, create, publish or review a blog post or article for a site, or asks to add, improve or suggest internal links.
---

# Internal Linking

Every new article gets linked **to** related older content, and older content gets linked **to** the new article. This helps Google find and index the new page faster, passes value from established pages to new ones, and gives readers more on the topic, which is the most important reason. The rules come from Neil Patel's guide; see [references/neil-patel-guide.md](references/neil-patel-guide.md) for the reasoning behind each one.

```
Inventory ──▶ Pick targets ──▶ Links in the new article ──▶ Backlinks from older articles ──approve──▶ Apply ──▶ Verify + report
```

## When to use

- Writing a new article, blog post or guide for a site, or reviewing one before it's published.
- The user asks to add, improve or suggest internal links for a page.
- Not for external links or backlink building (links from other sites).

## 1. Project conventions

Links must look like the site's editors wrote them. Before adding any link:

1. Read the project's rules: `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, the README, and any editorial or style guide.
2. Read **2 or 3 existing articles**, preferably recent ones (`git log`) in the same category, and match:
   - **Link format:** Markdown `[text](/blog/slug/)`, HTML `<a href>`, a framework component (`<Link>`, Hugo `{{< ref >}}`, Jekyll `{% post_url %}`, `[[wikilinks]]`), relative or absolute URLs, trailing slash, locale prefix (`/br/`).
   - **Where articles live** (`content/`, `_posts/`, `src/pages/`, a CMS export) and how a file maps to its URL (slug in frontmatter, file name, date folders).
   - **Language and tone** of the anchor text, which must be in the article's language.
   - **Related-content features** the site already has (frontmatter `related:`, tags, series). Keep using them, but they don't replace links in the body.
3. Name the files you followed in your report, e.g. *"link format follows `content/blog/seo-basico.md`: relative Markdown links with trailing slash"*.

The site's conventions decide the format. The rules in [section 4](#4-rules-that-always-apply) always apply.

## 2. Build the inventory of existing pages

List the pages that could be linked, with their URL, title, main topic and keywords:

- **Content in the repository:** read the frontmatter (title, description, tags, categories, slug, date) and headings of every article. Skip drafts and unpublished pages (`draft: true`, future dates).
- **No content in the repository:** use the site's `sitemap.xml`, its blog index or category pages. Ask the user for the domain if you don't know it.
- **Conversion pages:** ask the user which pages convert best (sales pages, squeeze pages, lead magnets, top articles), or read them from analytics data they provide. Don't guess.

For a large site, narrow the inventory by the new article's category, tags and keywords before reading full articles.

## 3. Pick the targets

Score each candidate by how much the topics overlap with the new article. Prefer:

1. **Content-rich articles** (long-form guides and posts) that cover a subtopic the new article mentions, so a reader who wants to go deeper has somewhere to go.
2. **High-converting pages**, when the new article naturally leads to them.

Don't link to the homepage, About, Contact or other pages the navigation already covers, unless it's a conversion page that fits the context.

## 4. Rules that always apply

| Rule | Do | Don't |
|------|----|-------|
| **How many** | Link the new article to **at least 5 older articles** (never fewer than 4). Link each target once | Force a link where no topic overlaps just to reach the number. If the site has fewer related articles, link what fits and say so |
| **Where** | Inside the body, in the sentence where the topics overlap | Dump links at the end ("click here for more content"), in a generic list or a "related posts" block as the only links |
| **Anchor text** | A few descriptive words, or at most one sentence, that say what the target page is about, e.g. *"…o que é [SEO black hat](/blog/seo-black-hat/) e por que evitar"* | Exact-match keyword anchors repeated everywhere, "click here"/"clique aqui"/"leia mais", a link spanning more than one sentence or a whole paragraph, the same anchor for different targets |
| **Follow** | Plain links | `rel="nofollow"` on internal links |
| **Value** | Each link gives the reader more on what they're reading at that point | Links that only serve SEO |

Vary the anchor text across links to the same page from different articles. Rewrite a sentence slightly if needed so the anchor reads naturally, but don't change its meaning.

## 5. Add links to the new article

1. If the article is still being written, plan where each link goes and write the sentences with the links in them. If it already exists, insert the links into the existing sentences.
2. Use the link format from [section 1](#1-project-conventions).

## 6. Propose backlinks from older articles

Established pages linking to the new one pass it fresh value. For each of the most related older articles (aim for at least 3):

1. Find the paragraph where the new article's topic comes up, and write the sentence with the link to the new article.
2. If the older article is outdated, also suggest refreshing it, as the guide recommends: a short intro paragraph saying what was updated, a few paragraphs of new or updated information, and links to recent content.

**Stop.** Show the proposed changes to older articles, as a table with the file, the paragraph, the anchor text and the target, and wait for the user's approval. Editing published articles changes live content, so only apply what the user approves.

## 7. Verify and report

1. Check every link you added points to a page that exists and is published: a file in the repository that maps to that URL, or a URL in the sitemap. Fix or remove broken ones.
2. Check none of the rules in [section 4](#4-rules-that-always-apply) is broken (count, placement, anchor length, no nofollow, no duplicates).
3. Report:
   - the links in the new article: anchor text → target, and why it's related,
   - the backlinks added to older articles, and any proposed but not applied,
   - the conventions you followed and the files they came from,
   - anything missing, e.g. *"only 3 related articles exist; consider writing about X to link here later"*.

Don't commit or publish. The user reviews and publishes.

## Example

**Input:** "Write a post about Core Web Vitals for our blog" (Hugo site in Portuguese, posts in `content/blog/`).

**Output (report excerpt):**

| Anchor text | Target | Why |
|-------------|--------|-----|
| auditoria técnica de SEO | `/blog/auditoria-seo/` | The post's checklist step points to the full audit guide |
| velocidade de carregamento do site | `/blog/site-lento/` | LCP section; that guide covers image and server fixes |
| SEO para celulares | `/blog/seo-mobile/` | CLS and INP are measured on mobile first |
| como o Google indexa páginas | `/blog/indexacao-google/` | Intro explains why crawl matters |
| ferramentas gratuitas de SEO | `/blog/ferramentas-seo/` | Measuring section mentions PageSpeed Insights and Search Console |
| consultoria de SEO | `/consultoria/` | High-converting page, closing call to action |

Backlinks proposed: `site-lento.md` (paragraph 3), `auditoria-seo.md` (section "Desempenho"), `seo-mobile.md` (intro). Link format follows `content/blog/seo-mobile.md` and `content/blog/auditoria-seo.md`: Hugo `{{< ref >}}` shortcodes.
