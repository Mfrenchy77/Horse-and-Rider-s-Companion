/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", { "code": 120, "ignoreUrls": true, "ignoreStrings": true, "ignoreTemplateLiterals": true, "ignoreComments": true }] */

'use strict';

const dns = require('node:dns');
const net = require('node:net');

const DEFAULT_HEADERS = {
  'user-agent':
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
    '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  'accept':
    'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,' +
    'image/webp,image/apng,*/*;q=0.8',
};

const MAX_HTML_BYTES = 2 * 1024 * 1024;
const MAX_REDIRECTS = 5;
const REQUEST_TIMEOUT_MS = 9000;
const RATE_WINDOW_MS = 60 * 1000;
const RATE_LIMIT_MAX = 30;
const MAX_RATE_KEYS = 2000;

const ALLOWED_ORIGINS = new Set([
  'https://horse-and-riders-compani-d2bd4.web.app',
  'https://horse-and-riders-compani-d2bd4.firebaseapp.com',
  'https://horseandriderscompanion.com',
  'https://www.horseandriderscompanion.com',
]);

class HttpStatusError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

let cheerioMod = null;
let jsdomMod = null;
let readabilityMod = null;

function getCheerio() {
  if (!cheerioMod) cheerioMod = require('cheerio');
  return cheerioMod;
}

function getReadability() {
  if (!jsdomMod) jsdomMod = require('jsdom');
  if (!readabilityMod) readabilityMod = require('@mozilla/readability');
  return {
    JSDOM: jsdomMod.JSDOM,
    Readability: readabilityMod.Readability,
  };
}

function isOriginAllowed(origin, {allowLocalhost = false} = {}) {
  if (!origin || typeof origin !== 'string') return false;
  if (ALLOWED_ORIGINS.has(origin)) return true;
  if (allowLocalhost && /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin)) {
    return true;
  }
  return false;
}

function applyCors(req, res, {allowLocalhost = process.env.FUNCTIONS_EMULATOR === 'true'} = {}) {
  const origin = req?.headers?.origin;
  res.set?.('Vary', 'Origin');
  if (origin) {
    if (!isOriginAllowed(origin, {allowLocalhost})) {
      res.status(403).json({error: 'Origin not allowed'});
      return false;
    }
    res.set?.('Access-Control-Allow-Origin', origin);
    res.set?.('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set?.('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.set?.('Access-Control-Max-Age', '3600');
  }
  if (req?.method === 'OPTIONS') {
    if (typeof res.send === 'function') {
      res.status(204).send('');
    } else {
      res.status(204).json({});
    }
    return false;
  }
  return true;
}

function ipv4Bytes(ip) {
  const parts = ip.split('.');
  if (parts.length !== 4) return null;
  const nums = parts.map((p) => Number(p));
  if (nums.some((n) => !Number.isInteger(n) || n < 0 || n > 255)) return null;
  return nums;
}

function extractMappedIpv4(normalizedIp) {
  const lower = normalizedIp.toLowerCase();
  let rest = null;
  if (lower.startsWith('::ffff:')) {
    rest = lower.slice('::ffff:'.length);
  } else {
    const expandedMatch = lower.match(/^(?:0{1,4}:){5}ffff:(.+)$/i);
    if (expandedMatch) rest = expandedMatch[1];
  }
  if (!rest) return null;
  if (net.isIPv4(rest)) return rest;
  const hexGroups = rest.split(':');
  if (hexGroups.length !== 2) return null;
  const hi = Number.parseInt(hexGroups[0], 16);
  const lo = Number.parseInt(hexGroups[1], 16);
  if (!Number.isInteger(hi) || !Number.isInteger(lo)) return null;
  if (hi < 0 || hi > 0xffff || lo < 0 || lo > 0xffff) return null;
  return `${(hi >> 8) & 0xff}.${hi & 0xff}.${(lo >> 8) & 0xff}.${lo & 0xff}`;
}

function isDisallowedIp(rawIp) {
  if (!rawIp || typeof rawIp !== 'string') return true;
  const ip = rawIp.trim().replace(/^\[/, '').replace(/\]$/, '').split('%')[0].toLowerCase();
  const mapped = extractMappedIpv4(ip);
  if (mapped) return isDisallowedIp(mapped);

  const family = net.isIP(ip);
  if (family === 4) {
    const b = ipv4Bytes(ip);
    if (!b) return true;
    const [a, c] = b;
    if (a === 0 || a === 10 || a === 127) return true;
    if (a === 100 && c >= 64 && c <= 127) return true;
    if (a === 169 && c === 254) return true;
    if (a === 172 && c >= 16 && c <= 31) return true;
    if (a === 192 && c === 0 && (b[2] === 0 || b[2] === 2)) return true;
    if (a === 192 && c === 168) return true;
    if (a === 198 && (c === 18 || c === 19)) return true;
    if (a === 198 && c === 51 && b[2] === 100) return true;
    if (a === 203 && c === 0 && b[2] === 113) return true;
    if (a >= 224) return true;
    return false;
  }

  if (family === 6) {
    if (ip === '::' || ip === '::1') return true;
    const firstHex = ip.split(':')[0];
    if (firstHex.startsWith('fc') || firstHex.startsWith('fd')) return true;
    if (firstHex.startsWith('fe8') || firstHex.startsWith('fe9') ||
        firstHex.startsWith('fea') || firstHex.startsWith('feb')) {
      return true;
    }
    if (firstHex.startsWith('ff')) return true;
    if (ip.startsWith('2001:db8:') || ip.startsWith('2001:0db8:')) return true;
    return false;
  }

  return true;
}

async function defaultLookupFn(hostname, opts) {
  return dns.promises.lookup(hostname, opts);
}

async function assertSafeRemoteUrl(rawUrl, {lookupFn = defaultLookupFn} = {}) {
  let parsed;
  try {
    parsed = new URL(rawUrl);
  } catch {
    throw new HttpStatusError(400, 'Invalid URL');
  }
  if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
    throw new HttpStatusError(400, 'Only HTTP and HTTPS URLs are supported');
  }
  if (parsed.username || parsed.password) {
    throw new HttpStatusError(400, 'URL credentials are not allowed');
  }

  const host = parsed.hostname.toLowerCase().replace(/^\[/, '').replace(/\]$/, '');
  if (!host ||
      host === 'localhost' ||
      host.endsWith('.localhost') ||
      host.endsWith('.local') ||
      host.endsWith('.internal')) {
    throw new HttpStatusError(400, 'Disallowed destination host');
  }

  if (net.isIP(host)) {
    if (isDisallowedIp(host)) {
      throw new HttpStatusError(400, 'Disallowed network destination');
    }
    return parsed.toString();
  }

  let records;
  try {
    records = await lookupFn(host, {all: true, verbatim: true});
  } catch {
    throw new HttpStatusError(502, 'Unable to resolve destination host');
  }
  const list = Array.isArray(records) ? records : (records ? [records] : []);
  if (list.length === 0) {
    throw new HttpStatusError(502, 'Destination host resolved to no addresses');
  }
  for (const rec of list) {
    const addr = typeof rec === 'string' ? rec : rec?.address;
    if (isDisallowedIp(addr)) {
      throw new HttpStatusError(400, 'Disallowed private or reserved IP destination');
    }
  }
  return parsed.toString();
}

async function safeFetch(
    rawUrl,
    {
      fetchFn = fetch,
      lookupFn = defaultLookupFn,
      signal,
      method = 'GET',
      headers = DEFAULT_HEADERS,
      maxRedirects = MAX_REDIRECTS,
    } = {},
) {
  let currentUrl = await assertSafeRemoteUrl(rawUrl, {lookupFn});
  let currentMethod = method;

  for (let hop = 0; hop <= maxRedirects; hop++) {
    const resp = await fetchFn(currentUrl, {
      method: currentMethod,
      headers,
      redirect: 'manual',
      signal,
    });

    const location = resp.headers?.get?.('location');
    const isRedirect = resp.status >= 300 && resp.status < 400 && Boolean(location);
    if (!isRedirect) {
      const finalUrl = resp.url || currentUrl;
      if (finalUrl && finalUrl !== currentUrl) {
        await assertSafeRemoteUrl(finalUrl, {lookupFn});
      }
      return resp;
    }

    await resp.body?.cancel?.();
    if (hop >= maxRedirects) {
      throw new HttpStatusError(400, 'Too many redirects');
    }

    let nextUrl;
    try {
      nextUrl = new URL(location, currentUrl).toString();
    } catch {
      throw new HttpStatusError(400, 'Invalid redirect URL');
    }
    currentUrl = await assertSafeRemoteUrl(nextUrl, {lookupFn});
    if (resp.status === 303 || ((resp.status === 301 || resp.status === 302) && currentMethod === 'POST')) {
      currentMethod = 'GET';
    }
  }

  throw new HttpStatusError(400, 'Too many redirects');
}

async function readTextWithLimit(resp, maxBytes = MAX_HTML_BYTES) {
  const lenHeader = Number(resp.headers?.get?.('content-length') || 0);
  if (Number.isFinite(lenHeader) && lenHeader > maxBytes) {
    await resp.body?.cancel?.();
    throw new HttpStatusError(413, 'Upstream response exceeds size limit');
  }

  if (resp.body && typeof resp.body.getReader === 'function') {
    const reader = resp.body.getReader();
    const decoder = new TextDecoder('utf-8', {fatal: false});
    let received = 0;
    let out = '';
    let done = false;
    while (!done) {
      const chunk = await reader.read();
      done = Boolean(chunk.done);
      if (done) break;
      const value = chunk.value;
      received += value ? value.byteLength : 0;
      if (received > maxBytes) {
        await reader.cancel().catch(() => {});
        throw new HttpStatusError(413, 'Upstream response exceeds size limit');
      }
      out += decoder.decode(value, {stream: true});
    }
    out += decoder.decode();
    return out;
  }

  const text = await resp.text();
  if (Buffer.byteLength(String(text || ''), 'utf8') > maxBytes) {
    throw new HttpStatusError(413, 'Upstream response exceeds size limit');
  }
  return text;
}

function createRateLimiter({limit = RATE_LIMIT_MAX, windowMs = RATE_WINDOW_MS, now = () => Date.now()} = {}) {
  const buckets = new Map();
  return function check(key) {
    const t = now();
    const bucket = buckets.get(key);
    if (!bucket || t >= bucket.resetAt) {
      if (buckets.size >= MAX_RATE_KEYS) {
        for (const [k, v] of buckets.entries()) {
          if (t >= v.resetAt) buckets.delete(k);
          if (buckets.size < MAX_RATE_KEYS) break;
        }
      }
      buckets.set(key, {count: 1, resetAt: t + windowMs});
      return {allowed: true};
    }
    if (bucket.count >= limit) {
      return {
        allowed: false,
        retryAfterSeconds: Math.max(1, Math.ceil((bucket.resetAt - t) / 1000)),
      };
    }
    bucket.count += 1;
    return {allowed: true};
  };
}

function clientIpKey(req) {
  const forwarded = String(req?.headers?.['x-forwarded-for'] || '').split(',')[0].trim();
  return forwarded || req?.ip || 'anonymous';
}

async function requireVerifiedUser(req, verifyIdToken) {
  const authHeader = String(req?.headers?.authorization || '');
  const match = authHeader.match(/^Bearer\s+(.+)$/i);
  if (!match || !match[1]) {
    throw new HttpStatusError(401, 'Authentication required');
  }
  let decoded;
  try {
    decoded = await verifyIdToken(match[1].trim());
  } catch {
    throw new HttpStatusError(401, 'Invalid authentication token');
  }
  if (!decoded || decoded.email_verified !== true) {
    throw new HttpStatusError(403, 'Verified email required');
  }
  return decoded;
}

function badRequest(res, msg) {
  res.status(400).json({error: msg});
}

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

function isSameOrigin(a, b) {
  try {
    return new URL(a).origin === new URL(b).origin;
  } catch {
    return false;
  }
}

function looksLikeDirectImage(u) {
  try {
    const p = new URL(u).pathname.toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.svg'].some((ext) => p.endsWith(ext));
  } catch {
    return false;
  }
}

function pathLooksLikeWpUpload(u) {
  try {
    const p = new URL(u).pathname.toLowerCase();
    return p.includes('/wp-content/uploads') || p.includes('/uploads/');
  } catch {
    return false;
  }
}

async function isImageUrl(u, signal, {fetchFn = fetch, lookupFn = defaultLookupFn} = {}) {
  try {
    let r = await safeFetch(u, {
      method: 'HEAD',
      headers: DEFAULT_HEADERS,
      signal,
      fetchFn,
      lookupFn,
    });
    let ok = r.ok && String(r.headers?.get?.('content-type') || '').toLowerCase().startsWith('image/');
    await r.body?.cancel?.();
    if (!ok) {
      r = await safeFetch(u, {
        method: 'GET',
        headers: {...DEFAULT_HEADERS, Range: 'bytes=0-0'},
        signal,
        fetchFn,
        lookupFn,
      });
      ok = r.ok && String(r.headers?.get?.('content-type') || '').toLowerCase().startsWith('image/');
      await r.body?.cancel?.();
    }
    return ok;
  } catch {
    return false;
  }
}

function collectImageCandidates(html, baseUrl) {
  const cheerio = getCheerio();
  const $ = cheerio.load(html);
  const list = [];

  $('meta[property="og:image"], meta[name="twitter:image"], meta[property="og:image:secure_url"]').each((_, el) => {
    const content = $(el).attr('content');
    if (content) list.push(absUrl(content, baseUrl));
  });

  $('link[rel="image_src"]').each((_, el) => {
    const href = $(el).attr('href');
    if (href) list.push(absUrl(href, baseUrl));
  });

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

  $('a[href]').each((_, el) => {
    const href = $(el).attr('href');
    if (href && looksLikeDirectImage(href)) {
      list.push(absUrl(href, baseUrl));
    }
  });

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

function sortCandidatesHeuristically(candidates, pageUrl) {
  const scoreOf = (u) => {
    let s = 0;
    if (isSameOrigin(u, pageUrl)) s += 40;
    if (pathLooksLikeWpUpload(u)) s += 30;
    if (looksLikeDirectImage(u)) s += 10;
    try {
      const host = new URL(u).host.toLowerCase();
      if (/^i\d*\.wp\.com$/.test(host)) s -= 10;
      if (host.endsWith('gravatar.com')) s -= 10;
    } catch {
      // ignore
    }
    try {
      const pathname = new URL(u).pathname.toLowerCase();
      if (/-full\b/.test(pathname)) s += 3;
      if (/[_-]\d{2,4}\b/.test(pathname)) s += 2;
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

async function wpMediaCandidates(
    pageUrl,
    originalUrl,
    signal,
    {fetchFn = fetch, lookupFn = defaultLookupFn} = {},
) {
  const out = [];
  try {
    const base = new URL(pageUrl);
    const origin = base.origin;

    const from = (u) => {
      try {
        return new URL(u).pathname.split('/').pop() || '';
      } catch {
        return '';
      }
    };
    const file = from(originalUrl || pageUrl);
    const nameNoExt = file.replace(/\.[a-z0-9]+$/i, '');

    const variants = Array.from(new Set([
      nameNoExt,
      nameNoExt.replace(/[_-]\d+$/, ''),
      nameNoExt.replace(/_/g, '-'),
      nameNoExt.replace(/-/g, '_'),
      nameNoExt.toLowerCase(),
      nameNoExt.toUpperCase(),
    ])).filter(Boolean);

    try {
      const oembed = `${origin}/wp-json/oembed/1.0/embed?url=${encodeURIComponent(pageUrl)}`;
      const r = await safeFetch(oembed, {headers: DEFAULT_HEADERS, signal, fetchFn, lookupFn});
      if (r.ok) {
        const j = await r.json();
        if (j && j.thumbnail_url) out.push(j.thumbnail_url);
      }
    } catch {
      // ignore
    }

    for (const v of variants.slice(0, 2)) {
      if (signal.aborted) break;
      const api = `${origin}/wp-json/wp/v2/media?search=${encodeURIComponent(v)}`;
      const r = await safeFetch(api, {headers: DEFAULT_HEADERS, signal, fetchFn, lookupFn});
      if (!r.ok) continue;
      const arr = await r.json();
      for (const item of (Array.isArray(arr) ? arr : [])) {
        if (item && item.source_url) out.push(item.source_url);
        const sizes = (item && item.media_details && item.media_details.sizes) || {};
        if (sizes.full && sizes.full.source_url) out.push(sizes.full.source_url);
      }
      if (out.length >= 6) break;
    }
  } catch {
    // ignore
  }

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

function proxied(u) {
  return `https://wsrv.nl/?url=${encodeURIComponent(u)}`;
}

function requiresTopLevelBrowser(headers) {
  const frameOptions = headers.get('x-frame-options') || '';
  if (/\b(?:deny|sameorigin)\b/i.test(frameOptions)) return true;
  const policy = headers.get('content-security-policy') || '';
  return policy.split(/[;,]/).some((directive) => {
    const [name, ...sources] = directive.trim().toLowerCase().split(/\s+/);
    return name === 'frame-ancestors' && !sources.includes('*');
  });
}

function handleEndpointError(res, logger, err) {
  if (err instanceof HttpStatusError) {
    return res.status(err.status).json({error: err.message});
  }
  if (err && err.name === 'TimeoutError') {
    return res.status(504).json({error: 'Upstream request timed out'});
  }
  logger?.error?.(err);
  return res.status(500).json({error: String(err?.message || err)});
}

function createPreviewMetaHandler({
  verifyIdToken,
  fetchFn = fetch,
  lookupFn = defaultLookupFn,
  logger,
  rateLimiter = createRateLimiter(),
  allowLocalhostCors = process.env.FUNCTIONS_EMULATOR === 'true',
} = {}) {
  return async (req, res) => {
    if (!applyCors(req, res, {allowLocalhost: allowLocalhostCors})) return;
    try {
      if (req.method !== 'POST') return badRequest(res, 'Use POST');
      const {url} = req.body || {};
      if (!url || typeof url !== 'string') return badRequest(res, 'Missing url');

      const user = await requireVerifiedUser(req, verifyIdToken);
      const rate = rateLimiter(`previewMeta:${user.uid}`);
      if (!rate.allowed) {
        res.set?.('Retry-After', String(rate.retryAfterSeconds));
        return res.status(429).json({error: 'Too many requests'});
      }

      const signal = AbortSignal.timeout(REQUEST_TIMEOUT_MS);
      const r = await safeFetch(url, {fetchFn, lookupFn, signal});
      if (!r.ok) {
        await r.body?.cancel?.();
        return res.status(502).json({error: `Fetch failed: ${r.status}`});
      }

      const contentType = (r.headers?.get?.('content-type') || '').toLowerCase();
      if (!contentType.includes('text/html')) {
        await r.body?.cancel?.();
        return res.status(415).json({error: 'URL is not HTML content'});
      }

      const html = await readTextWithLimit(r, MAX_HTML_BYTES);
      const cheerio = getCheerio();
      const $ = cheerio.load(html);

      const title =
        $('meta[property="og:title"]').attr('content') ||
        $('title').text() ||
        '';
      const description =
        $('meta[name="description"]').attr('content') ||
        $('meta[property="og:description"]').attr('content') ||
        '';
      const rawImage =
        $('meta[property="og:image"]').attr('content') ||
        $('meta[name="twitter:image"]').attr('content') ||
        $('meta[property="og:image:secure_url"]').attr('content') ||
        '';

      const finalUrl = r.url || url;
      const image = absUrl(rawImage, finalUrl);
      return res.json({
        url: finalUrl,
        title,
        description,
        image,
        ...(requiresTopLevelBrowser(r.headers) ? {blocksEmbedding: true} : {}),
      });
    } catch (e) {
      return handleEndpointError(res, logger, e);
    }
  };
}

function createFetchReadableHandler({
  verifyIdToken,
  fetchFn = fetch,
  lookupFn = defaultLookupFn,
  logger,
  rateLimiter = createRateLimiter(),
  allowLocalhostCors = process.env.FUNCTIONS_EMULATOR === 'true',
} = {}) {
  return async (req, res) => {
    if (!applyCors(req, res, {allowLocalhost: allowLocalhostCors})) return;
    try {
      if (req.method !== 'POST') return badRequest(res, 'Use POST');
      const {url} = req.body || {};
      if (!url || typeof url !== 'string') return badRequest(res, 'Missing url');

      const user = await requireVerifiedUser(req, verifyIdToken);
      const rate = rateLimiter(`fetchReadable:${user.uid}`);
      if (!rate.allowed) {
        res.set?.('Retry-After', String(rate.retryAfterSeconds));
        return res.status(429).json({error: 'Too many requests'});
      }

      const signal = AbortSignal.timeout(REQUEST_TIMEOUT_MS);
      const r = await safeFetch(url, {fetchFn, lookupFn, signal});
      if (!r.ok) {
        await r.body?.cancel?.();
        return res.status(502).json({error: `Fetch failed: ${r.status}`});
      }

      const contentType = (r.headers?.get?.('content-type') || '').toLowerCase();
      if (!contentType.includes('text/html')) {
        await r.body?.cancel?.();
        return res.status(415).json({error: 'URL is not HTML content'});
      }

      const html = await readTextWithLimit(r, MAX_HTML_BYTES);
      const cheerio = getCheerio();
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

      const finalUrl = r.url || url;
      const {JSDOM, Readability} = getReadability();
      const dom = new JSDOM(html, {url: finalUrl});
      const article = new Readability(dom.window.document).parse();

      if (!article) return res.status(422).json({error: 'Unable to parse article'});

      return res.json({
        url: finalUrl,
        title: article.title || $('title').text() || '',
        description: article.excerpt || metaDesc || '',
        image: absUrl(ogImage, finalUrl),
        byline: article.byline || '',
        length: article.length || 0,
        siteName: $('meta[property="og:site_name"]').attr('content') || '',
        content: article.content,
        textContent: article.textContent,
      });
    } catch (e) {
      return handleEndpointError(res, logger, e);
    }
  };
}

function createResolveImageHandler({
  fetchFn = fetch,
  lookupFn = defaultLookupFn,
  logger,
  rateLimiter = createRateLimiter(),
  allowLocalhostCors = process.env.FUNCTIONS_EMULATOR === 'true',
} = {}) {
  return async (req, res) => {
    if (!applyCors(req, res, {allowLocalhost: allowLocalhostCors})) return;
    try {
      if (req.method !== 'POST') return badRequest(res, 'Use POST');
      const {url, hint} = req.body || {};
      if (!url || typeof url !== 'string') return badRequest(res, 'Missing url');

      const rate = rateLimiter(`resolveImage:${clientIpKey(req)}`);
      if (!rate.allowed) {
        res.set?.('Retry-After', String(rate.retryAfterSeconds));
        return res.status(429).json({error: 'Too many requests'});
      }

      const signal = AbortSignal.timeout(REQUEST_TIMEOUT_MS);
      const resp = await safeFetch(url, {fetchFn, lookupFn, signal});
      if (!resp.ok) {
        await resp.body?.cancel?.();
        return res.status(502).json({error: `Fetch failed: ${resp.status}`});
      }
      const finalUrl = resp.url || url;
      const contentType = (resp.headers?.get?.('content-type') || '').toLowerCase();

      if (contentType.startsWith('image/')) {
        await resp.body?.cancel?.();
        res.set?.('Cache-Control', 'public, max-age=1800, s-maxage=3600');
        return res.json({resolvedUrl: finalUrl, proxiedUrl: proxied(finalUrl)});
      }
      if (!contentType.includes('text/html')) {
        await resp.body?.cancel?.();
        return res.status(404).json({error: 'No image found'});
      }

      const html = await readTextWithLimit(resp, MAX_HTML_BYTES);
      const seen = new Set();
      let totalProbes = 0;
      const maxTotalProbes = 6;

      const findImage = async (candidates, limit) => {
        let checked = 0;
        for (const candidate of candidates) {
          if (signal.aborted || checked >= limit || totalProbes >= maxTotalProbes) break;
          const image = absUrl(candidate, finalUrl);
          if (!image || seen.has(image)) continue;
          seen.add(image);
          checked += 1;
          totalProbes += 1;
          if (await isImageUrl(image, signal, {fetchFn, lookupFn})) return image;
        }
        return null;
      };

      const candidates = collectImageCandidates(html, finalUrl);
      let image = await findImage([...candidates.slice(0, 5), hint], 6);
      if (!image && !signal.aborted && totalProbes < maxTotalProbes) {
        const wp = await wpMediaCandidates(
            finalUrl,
            hint || candidates[0] || url,
            signal,
            {fetchFn, lookupFn},
        );
        image = await findImage(sortCandidatesHeuristically(wp, finalUrl), maxTotalProbes - totalProbes);
      }
      if (image) {
        res.set?.('Cache-Control', 'public, max-age=1800, s-maxage=3600');
        return res.json({resolvedUrl: image, proxiedUrl: proxied(image)});
      }
      if (signal.aborted) return res.status(504).json({error: 'Image lookup timed out'});
      return res.status(404).json({error: 'No image found'});
    } catch (e) {
      return handleEndpointError(res, logger, e);
    }
  };
}

module.exports = {
  ALLOWED_ORIGINS,
  MAX_HTML_BYTES,
  MAX_REDIRECTS,
  absUrl,
  applyCors,
  assertSafeRemoteUrl,
  collectImageCandidates,
  createFetchReadableHandler,
  createPreviewMetaHandler,
  createRateLimiter,
  createResolveImageHandler,
  isDisallowedIp,
  isImageUrl,
  isOriginAllowed,
  readTextWithLimit,
  requiresTopLevelBrowser,
  safeFetch,
  sortCandidatesHeuristically,
  wpMediaCandidates,
};
