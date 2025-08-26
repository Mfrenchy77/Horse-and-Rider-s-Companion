/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", { "code": 120, "ignoreUrls": true, "ignoreStrings": true, "ignoreTemplateLiterals": true, "ignoreComments": true }] */

'use strict';

const cors = require('cors')({origin: true});
const {JSDOM} = require('jsdom');
const {Readability} = require('@mozilla/readability');
const cheerio = require('cheerio');
const {onRequest} = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');

/** ------------------------------------------------------------------------ */
/** Shared helpers                                                           */
/** ------------------------------------------------------------------------ */

// Node 18+ (Cloud Functions v2) ships global fetch.

const DEFAULT_HEADERS = {
  'user-agent':
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
    '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  'accept':
    'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,' +
    'image/webp,image/apng,*/*;q=0.8',
};

/**
 * Send a 400 Bad Request with a JSON error.
 * @param {object} res Express-like response object
 * @param {string} msg Error message
 * @return {void}
 */
function badRequest(res, msg) {
  res.status(400).json({error: msg});
}

/**
 * Make a possibly-relative URL absolute against a base URL.
 * @param {string} maybeRelative URL string that may be relative
 * @param {string} baseUrl Base page URL
 * @return {string} Absolute URL (or original input if parsing fails)
 */
function absUrl(maybeRelative, baseUrl) {
  try {
    if (!maybeRelative) return '';
    const base = new URL(baseUrl);
    const u = new URL(maybeRelative, base);
    return u.toString();
  } catch {
    return maybeRelative || '';
  }
}

/**
 * Whether two URLs share the same origin.
 * @param {string} a First URL
 * @param {string} b Second URL
 * @return {boolean} True if same origin
 */
function isSameOrigin(a, b) {
  try {
    return new URL(a).origin === new URL(b).origin;
  } catch {
    return false;
  }
}

/**
 * Heuristic: does a URL string end with a common image extension?
 * @param {string} u URL to test
 * @return {boolean} True if URL path looks like an image file
 */
function looksLikeDirectImage(u) {
  try {
    const p = new URL(u).pathname.toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.svg'].some((ext) => p.endsWith(ext));
  } catch {
    return false;
  }
}

/**
 * Heuristic: does a URL path look like a WordPress/uploads location?
 * @param {string} u URL to test
 * @return {boolean} True if path suggests WP uploads
 */
function pathLooksLikeWpUpload(u) {
  try {
    const p = new URL(u).pathname.toLowerCase();
    return p.includes('/wp-content/uploads') || p.includes('/uploads/');
  } catch {
    return false;
  }
}

/**
 * Validate if URL returns an image. Some origins reject HEAD, so fall back to a tiny GET.
 * Always follows redirects and checks content-type.
 * @param {string} u URL to test
 * @return {Promise<boolean>} True if the URL serves image/* content
 */
async function isImageUrl(u) {
  try {
    let r = await fetch(u, {method: 'HEAD', redirect: 'follow', headers: DEFAULT_HEADERS});
    let ok = r.ok && String(r.headers.get('content-type') || '').toLowerCase().startsWith('image/');
    if (!ok) {
      // Some sites/CDNs reject HEAD, try range GET (first byte).
      r = await fetch(u, {
        method: 'GET',
        redirect: 'follow',
        headers: {...DEFAULT_HEADERS, Range: 'bytes=0-0'},
      });
      ok = r.ok && String(r.headers.get('content-type') || '').toLowerCase().startsWith('image/');
    }
    return ok;
  } catch {
    return false;
  }
}

/**
 * Collect image candidates from HTML:
 *  - og:image / twitter:image / og:image:secure_url
 *  - <link rel="image_src">
 *  - JSON-LD (image or {url})
 *  - <img src>, <img srcset>, <source srcset>
 *  - <a href="*.jpg|*.png|..."> (full-size images in galleries/lightboxes)
 * @param {string} html Raw HTML string
 * @param {string} baseUrl Base URL of the page
 * @return {string[]} De-duplicated list of absolute candidate URLs
 */
function collectImageCandidates(html, baseUrl) {
  const $ = cheerio.load(html);
  const list = [];

  // og:image + twitter:image + secure_url
  $('meta[property="og:image"], meta[name="twitter:image"], meta[property="og:image:secure_url"]').each((_, el) => {
    const content = $(el).attr('content');
    if (content) list.push(absUrl(content, baseUrl));
  });

  // <link rel="image_src">
  $('link[rel="image_src"]').each((_, el) => {
    const href = $(el).attr('href');
    if (href) list.push(absUrl(href, baseUrl));
  });

  // JSON-LD blocks: try to find "image" (string or {url})
  $('script[type="application/ld+json"]').each((_, el) => {
    try {
      const data = JSON.parse($(el).text());
      const images = [];
      (function walk(x) {
        if (!x) return;
        if (Array.isArray(x)) return x.forEach(walk);
        if (typeof x === 'object') {
          if (x.image) images.push(x.image);
          Object.values(x).forEach(walk);
        }
      })(data);
      const flattened = (images.flat && images.flat(99)) || images;
      flattened.forEach((v) => {
        if (typeof v === 'string') list.push(absUrl(v, baseUrl));
        else if (v && typeof v.url === 'string') list.push(absUrl(v.url, baseUrl));
      });
    } catch {
      // ignore JSON parse issues
    }
  });

  // <img src / srcset>
  $('img').each((_, el) => {
    const src = $(el).attr('src');
    if (src) list.push(absUrl(src, baseUrl));

    const srcset = $(el).attr('srcset');
    if (srcset) {
      srcset
          .split(',')
          .map((s) => s.trim().split(' ')[0])
          .forEach((u) => {
            if (u) list.push(absUrl(u, baseUrl));
          });
    }
  });

  // <source srcset> within <picture>
  $('source[srcset]').each((_, el) => {
    const srcset = $(el).attr('srcset');
    if (!srcset) return;
    srcset
        .split(',')
        .map((s) => s.trim().split(' ')[0])
        .forEach((u) => {
          if (u) list.push(absUrl(u, baseUrl));
        });
  });

  // <a href="*.jpg|*.png|..."> (full-size images in galleries/lightboxes)
  $('a[href]').each((_, el) => {
    const href = $(el).attr('href');
    if (href && looksLikeDirectImage(href)) {
      list.push(absUrl(href, baseUrl));
    }
  });

  // de-dupe in order
  const seen = Object.create(null);
  const out = [];
  for (const u of list) {
    if (!u) continue;
    if (!seen[u]) {
      seen[u] = true;
      out.push(u);
    }
  }
  return out;
}

/**
 * Score and order candidate URLs to prefer:
 *  - same-origin as the page
 *  - WordPress uploads (/wp-content/uploads or /uploads/)
 *  - direct images vs. resizers/CDNs like i*.wp.com
 * @param {string[]} candidates Candidate URLs
 * @param {string} pageUrl Page URL for heuristics
 * @return {string[]} Ordered candidates (best first)
 */
function sortCandidatesHeuristically(candidates, pageUrl) {
  const scoreOf = (u) => {
    let s = 0;
    // same origin
    if (isSameOrigin(u, pageUrl)) s += 40;
    // classic WP media path
    if (pathLooksLikeWpUpload(u)) s += 30;
    // direct image file feel
    if (looksLikeDirectImage(u)) s += 10;
    // avoid common resizer/cdn hosts a bit
    try {
      const host = new URL(u).host.toLowerCase();
      if (/^i\d*\.wp\.com$/.test(host)) s -= 10;
      if (host.endsWith('gravatar.com')) s -= 10;
    } catch {
      // ignore
    }
    // filenames that look like originals (very loose heuristics)
    try {
      const pathname = new URL(u).pathname.toLowerCase();
      if (/-full\b/.test(pathname)) s += 3;
      if (/[_-]\d{2,4}\b/.test(pathname)) s += 2; // like _01, -1024
    } catch {
      // ignore
    }
    return s;
  };

  return candidates
      .map((u) => ({u, s: scoreOf(u)}))
      .sort((a, b) => b.s - a.s)
      .map(({u}) => u);
}

/**
 * WordPress REST media lookup often resolves CDN/S3/migrations.
 * Strategy:
 *  - Build a media search query from filename (and relaxed variants).
 *  - Prefer media_details.sizes.full.source_url and source_url.
 *  - Also attempts oEmbed thumbnail discovery.
 * @param {string} pageUrl Page URL (used for origin)
 * @param {string} originalUrl A related URL/filename to seed the search (e.g., OG image)
 * @return {Promise<string[]>} Candidate media URLs (absolute, de-duplicated)
 */
async function wpMediaCandidates(pageUrl, originalUrl) {
  const out = [];
  try {
    const base = new URL(pageUrl);
    const origin = base.origin;

    const from = (u) => {
      try { return new URL(u).pathname.split('/').pop() || ''; } catch { return ''; }
    };
    const file = from(originalUrl || pageUrl); // fallback to page filename
    const nameNoExt = file.replace(/\.[a-z0-9]+$/i, '');

    // Generate a few relaxed variants (strip trailing _\d  / hyphens vs underscores)
    const variants = Array.from(new Set([
      nameNoExt,
      nameNoExt.replace(/[_-]\d+$/, ''), // strip trailing index like _03
      nameNoExt.replace(/_/g, '-'),
      nameNoExt.replace(/-/g, '_'),
      nameNoExt.toLowerCase(),
      nameNoExt.toUpperCase(),
    ])).filter(Boolean);

    // Try oEmbed first (often returns a thumbnail_url)
    try {
      const oembed = `${origin}/wp-json/oembed/1.0/embed?url=${encodeURIComponent(pageUrl)}`;
      const r = await fetch(oembed, {headers: DEFAULT_HEADERS, redirect: 'follow'});
      if (r.ok) {
        const j = await r.json();
        if (j && j.thumbnail_url) out.push(j.thumbnail_url);
      }
    } catch {
      // ignore
    }

    // Try media search with variants (stop when we’ve found a few)
    for (const v of variants) {
      const api = `${origin}/wp-json/wp/v2/media?search=${encodeURIComponent(v)}`;
      const r = await fetch(api, {headers: DEFAULT_HEADERS, redirect: 'follow'});
      if (!r.ok) continue;
      const arr = await r.json();
      for (const item of (Array.isArray(arr) ? arr : [])) {
        if (item && item.source_url) out.push(item.source_url);
        const sizes = (item && item.media_details && item.media_details.sizes) || {};
        if (sizes.full && sizes.full.source_url) out.push(sizes.full.source_url);
      }
      if (out.length >= 6) break; // enough
    }
  } catch {
    // ignore
  }

  // de-dupe
  const seen = Object.create(null);
  const dedup = [];
  for (const u of out) {
    if (!u) continue;
    const abs = absUrl(u, pageUrl);
    if (!seen[abs]) {
      seen[abs] = true;
      dedup.push(abs);
    }
  }
  return dedup;
}

/**
 * Build a wsrv.nl proxy URL for a given image URL.
 * @param {string} u Direct image URL
 * @return {string} Proxied URL (images.weserv.nl)
 */
function proxied(u) {
  return `https://wsrv.nl/?url=${encodeURIComponent(u)}`;
}

/** ------------------------------------------------------------------------ */
/** previewMeta: POST { url } -> { url, title, description, image }          */
/** ------------------------------------------------------------------------ */
exports.previewMeta = onRequest(
    {region: 'us-central1', timeoutSeconds: 30, memory: '256MiB'},
    (req, res) => {
      cors(req, res, async () => {
        try {
          if (req.method !== 'POST') return badRequest(res, 'Use POST');
          const {url} = req.body || {};
          if (!url || typeof url !== 'string') return badRequest(res, 'Missing url');

          const r = await fetch(url, {headers: DEFAULT_HEADERS, redirect: 'follow'});
          if (!r.ok) return res.status(502).json({error: `Fetch failed: ${r.status}`});

          const contentType = (r.headers.get('content-type') || '').toLowerCase();
          if (!contentType.includes('text/html')) {
            return res.status(415).json({error: 'URL is not HTML content'});
          }

          const html = await r.text();
          const $ = cheerio.load(html);

          const title =
          $('meta[property="og:title"]').attr('content') ||
          $('title').text() ||
          '';

          const description =
          $('meta[name="description"]').attr('content') ||
          $('meta[property="og:description"]').attr('content') ||
          '';

          // Make image absolute if present
          const rawImage =
          $('meta[property="og:image"]').attr('content') ||
          $('meta[name="twitter:image"]').attr('content') ||
          $('meta[property="og:image:secure_url"]').attr('content') ||
          '';

          const image = absUrl(rawImage, r.url);
          res.json({url: r.url, title, description, image});
        } catch (e) {
          logger.error(e);
          res.status(500).json({error: String(e)});
        }
      });
    },
);

/** ------------------------------------------------------------------------ */
/** fetchReadable: POST { url } -> Readability article + extra meta          */
/** ------------------------------------------------------------------------ */
exports.fetchReadable = onRequest(
    {region: 'us-central1', timeoutSeconds: 60, memory: '512MiB'},
    (req, res) => {
      cors(req, res, async () => {
        try {
          if (req.method !== 'POST') return badRequest(res, 'Use POST');
          const {url} = req.body || {};
          if (!url || typeof url !== 'string') return badRequest(res, 'Missing url');

          const r = await fetch(url, {headers: DEFAULT_HEADERS, redirect: 'follow'});
          if (!r.ok) return res.status(502).json({error: `Fetch failed: ${r.status}`});

          const contentType = (r.headers.get('content-type') || '').toLowerCase();
          if (!contentType.includes('text/html')) {
            return res.status(415).json({error: 'URL is not HTML content'});
          }

          const html = await r.text();
          const $ = cheerio.load(html);

          const ogImage =
          $('meta[property="og:image"]').attr('content') ||
          $('meta[name="twitter:image"]').attr('content') ||
          $('meta[property="og:image:secure_url"]').attr('content') ||
          '';

          const metaDesc =
          $('meta[name="description"]').attr('content') ||
          $('meta[property="og:description"]').attr('content') ||
          '';

          const dom = new JSDOM(html, {url: r.url});
          const reader = new Readability(dom.window.document);
          const article = reader.parse(); // { title, content, textContent, byline, length, excerpt, siteName }

          if (!article) return res.status(422).json({error: 'Unable to parse article'});

          res.json({
            url: r.url,
            title: article.title || $('title').text() || '',
            description: article.excerpt || metaDesc || '',
            image: absUrl(ogImage, r.url),
            byline: article.byline || '',
            length: article.length || 0,
            siteName: $('meta[property="og:site_name"]').attr('content') || '',
            content: article.content, // sanitized HTML
            textContent: article.textContent,
          });
        } catch (e) {
          logger.error(e);
          res.status(500).json({error: String(e)});
        }
      });
    },
);

/** ------------------------------------------------------------------------ */
/** resolveImage: POST { url, hint? } -> { resolvedUrl, proxiedUrl }         */
/**  - Verifies real image URLs                                              */
/**  - Prefers WP uploads & same-origin                                      */
/**  - Adds oEmbed + <a href> image discovery                                */
/** ------------------------------------------------------------------------ */
exports.resolveImage = onRequest(
    {region: 'us-central1', timeoutSeconds: 45, memory: '512MiB'},
    (req, res) => {
      cors(req, res, async () => {
        try {
          if (req.method !== 'POST') return badRequest(res, 'Use POST');
          const {url, hint} = req.body || {};
          if (!url || typeof url !== 'string') return badRequest(res, 'Missing url');

          // 1) Fetch target (follow redirects)
          const resp = await fetch(url, {headers: DEFAULT_HEADERS, redirect: 'follow'});
          const finalUrl = resp.url;
          const contentType = (resp.headers.get('content-type') || '').toLowerCase();

          // If the target is already an image, we're done.
          if (contentType.startsWith('image/')) {
            const direct = finalUrl;
            return res.json({resolvedUrl: direct, proxiedUrl: proxied(direct)});
          }

          // 2) Parse HTML and gather candidates
          const html = await resp.text();
          const candidatesBase = collectImageCandidates(html, finalUrl);

          // 3) WordPress media lookup (often resolves CDN/S3/migrations)
          const wpCand = await wpMediaCandidates(finalUrl, hint || candidatesBase[0] || url);

          // 4) Optional hint first (front of the line)
          const all = [];
          if (hint) all.push(absUrl(hint, finalUrl));
          all.push(...candidatesBase);
          all.push(...wpCand);

          // 5) Sort heuristically to prioritize best bets
          const ordered = sortCandidatesHeuristically(
          // de-dup before scoring
              Array.from(new Set(all.map((u) => absUrl(u, finalUrl)))),
              finalUrl,
          );

          // 6) Validate in order; return first real image
          const seen = Object.create(null);
          for (const c of ordered) {
            if (!c) continue;
            const abs = absUrl(c, finalUrl);
            if (seen[abs]) continue;
            seen[abs] = true;

            if (await isImageUrl(abs)) {
              return res.json({resolvedUrl: abs, proxiedUrl: proxied(abs)});
            }
          }

          return res.status(404).json({error: 'No image found'});
        } catch (e) {
          logger.error(e);
          res.status(500).json({error: String(e)});
        }
      });
    },
);
