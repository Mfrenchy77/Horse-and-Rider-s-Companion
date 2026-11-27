/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const {publicEntry} = require('./dictionary');
const {resolvePublicInvitationPreview} = require('./invitations');

const DEFAULT_TITLE = 'Horse & Rider\'s Companion';
const DEFAULT_DESCRIPTION =
  'Track Rider and Horse horsemanship skills, explore the Skill Tree, and share educational resources.';
const DEFAULT_IMAGE_PATH = '/icons/Icon-512.png';
const DICTIONARY_IMAGE_PATH = '/images/dictionary-share-default.png';
const PROD_ORIGIN = 'https://horse-and-riders-compani-d2bd4.web.app';
const ALLOWED_HOSTS = new Set([
  'horse-and-riders-compani-d2bd4.web.app',
  'horse-and-riders-compani-d2bd4.firebaseapp.com',
  'horseandriderscompanion.com',
  'www.horseandriderscompanion.com',
]);
const DOC_ID_REGEX = /^[A-Za-z0-9._-]{1,120}$/;
const INDEX_HTML_CACHE_TTL_MS = 5 * 60 * 1000;

function escapeHtml(value) {
  return String(value || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
}

function isLocalHost(host) {
  return /^(localhost|127\.0\.0\.1)(:\d+)?$/i.test(host);
}

function isAllowedHost(host) {
  if (!host) return false;
  const lower = host.toLowerCase();
  if (ALLOWED_HOSTS.has(lower)) return true;
  if (isLocalHost(lower)) return true;
  return false;
}

function resolveRequestOrigin(req) {
  const forwardedHost = (req.headers['x-forwarded-host'] || '').split(',')[0].trim();
  const rawHost = (req.headers.host || '').trim();
  const host = isAllowedHost(forwardedHost) ?
    forwardedHost :
    (isAllowedHost(rawHost) ? rawHost : '');
  if (!host) return PROD_ORIGIN;
  if (isLocalHost(host)) {
    const forwardedProto = (req.headers['x-forwarded-proto'] || '').split(',')[0].trim();
    const proto = forwardedProto === 'https' ? 'https' : 'http';
    return `${proto}://${host}`;
  }
  return `https://${host}`;
}

function buildMetaTagsHtml(meta) {
  const title = escapeHtml(meta.title);
  const description = escapeHtml(meta.description);
  const image = escapeHtml(meta.image);
  const url = escapeHtml(meta.url);
  const siteName = escapeHtml(DEFAULT_TITLE);

  return [
    `<title>${title}</title>`,
    `<meta name="description" content="${description}">`,
    '<meta property="og:type" content="website">',
    `<meta property="og:site_name" content="${siteName}">`,
    `<meta property="og:title" content="${title}">`,
    `<meta property="og:description" content="${description}">`,
    `<meta property="og:image" content="${image}">`,
    `<meta property="og:url" content="${url}">`,
    `<link rel="canonical" href="${url}">`,
    '<meta name="twitter:card" content="summary">',
    `<meta name="twitter:title" content="${title}">`,
    `<meta name="twitter:description" content="${description}">`,
    `<meta name="twitter:image" content="${image}">`,
  ].join('\n  ');
}

function injectMetaIntoHtml(html, meta) {
  let out = String(html || '');
  out = out.replace(/<title>[\s\S]*?<\/title>/i, '');
  out = out.replace(/<meta\s+(?:name|property)="(?:description|og:[^"]+|twitter:[^"]+)"[^>]*>/gi, '');
  const tags = buildMetaTagsHtml(meta);
  if (/<\/head>/i.test(out)) {
    return out.replace(/<\/head>/i, `  ${tags}\n</head>`);
  }
  return `<!DOCTYPE html><html><head><meta charset="UTF-8">${tags}</head><body></body></html>`;
}

function fallbackHtmlShell(meta) {
  return injectMetaIntoHtml(
      '<!DOCTYPE html>\n<html>\n<head>\n  <base href="/">\n  <meta charset="UTF-8">\n' +
    '  <meta name="viewport" content="width=device-width, initial-scale=1.0">\n' +
    '  <script src="flutter_bootstrap.js" async></script>\n</head>\n<body></body>\n</html>',
      meta,
  );
}

async function resolvePublicSkill(db, rawSkillId) {
  const skillId = typeof rawSkillId === 'string' ? rawSkillId.trim() : '';
  if (!skillId || !DOC_ID_REGEX.test(skillId)) return null;

  const directSnap = await db.collection('SkillsV2').doc(skillId).get();
  if (directSnap.exists) {
    const data = directSnap.data() || {};
    if (data.status === 'active') {
      return {id: directSnap.id, ...data};
    }
    return null;
  }

  const legacySnap = await db
      .collection('SkillsV2')
      .where('legacyIds', 'array-contains', skillId)
      .limit(1)
      .get();
  if (!legacySnap.empty) {
    const doc = legacySnap.docs[0];
    const data = doc.data() || {};
    if (data.status === 'active') {
      return {id: doc.id, ...data};
    }
  }
  return null;
}

function safeDecodeURIComponent(value) {
  try {
    return decodeURIComponent(value);
  } catch (_) {
    return value;
  }
}

async function resolvePublicHorse(db, rawHorseId) {
  const horseId = typeof rawHorseId === 'string' ? rawHorseId.trim() : '';
  if (!horseId || !DOC_ID_REGEX.test(horseId)) return null;

  const snap = await db.collection('Public_Horse_Profile').doc(horseId).get();
  if (!snap.exists) return null;

  const data = snap.data() || {};
  const archiveStatus = data.archiveStatus || 'active';
  if (data.isPublic !== true || archiveStatus !== 'active') {
    return null;
  }

  return {
    id: snap.id,
    name: typeof data.name === 'string' ? data.name.trim() : '',
    breed: typeof data.breed === 'string' ? data.breed.trim() : '',
    gender: typeof data.gender === 'string' ? data.gender.trim() : '',
    color: typeof data.color === 'string' ? data.color.trim() : '',
    locationName: typeof data.locationName === 'string' ? data.locationName.trim() : '',
    picUrl: typeof data.picUrl === 'string' ? data.picUrl.trim() : '',
    saleListing: data.saleListing && typeof data.saleListing === 'object' ? {
      description: typeof data.saleListing.description === 'string' ?
        data.saleListing.description.trim() :
        '',
    } : null,
  };
}

function buildHorsePreviewMeta(origin, horse) {
  if (!horse) {
    return {
      title: DEFAULT_TITLE,
      description: DEFAULT_DESCRIPTION,
      image: `${origin}${DEFAULT_IMAGE_PATH}`,
      url: origin,
    };
  }

  const horseName = horse.name || 'Horse Profile';
  const summaryParts = [
    horse.breed,
    horse.gender,
    horse.color,
    horse.locationName,
  ].filter(Boolean);
  const description = (horse.saleListing && horse.saleListing.description) ||
    (summaryParts.length ? summaryParts.join(' · ') : DEFAULT_DESCRIPTION);
  const image = /^https?:\/\//i.test(horse.picUrl) ?
    horse.picUrl :
    `${origin}${DEFAULT_IMAGE_PATH}`;

  return {
    title: horse.saleListing ?
      `${horseName} (For Sale) — ${DEFAULT_TITLE}` :
      `${horseName} — ${DEFAULT_TITLE}`,
    description,
    image,
    url: `${origin}/Profile/Horse_Profile/${encodeURIComponent(horse.id)}`,
  };
}
function dictionaryPreviewImage(entry, origin) {
  const fallback = `${origin}${DICTIONARY_IMAGE_PATH}`;
  if (!entry || !Array.isArray(entry.media)) return fallback;

  const image = entry.media.find((item) => {
    if (!item || typeof item.url !== 'string') return false;

    try {
      const url = new URL(item.url);
      return url.protocol === 'https:' &&
        /\.(png|jpe?g|webp)(?:$|[?#])/i.test(url.pathname);
    } catch (_) {
      return false;
    }
  });

  return image ? image.url : fallback;
}

function sharePreviewHandler(db, {
  fetchFn = fetch,
  now = () => Date.now(),
  indexHtmlCacheTtlMs = INDEX_HTML_CACHE_TTL_MS,
} = {}) {
  const htmlCache = new Map();

  async function loadBaseHtml(origin) {
    if (indexHtmlCacheTtlMs > 0) {
      const cached = htmlCache.get(origin);
      if (cached && now() < cached.expiresAt) {
        return cached.html;
      }
    }
    try {
      const indexRes = await fetchFn(`${origin}/index.html`, {
        redirect: 'follow',
        signal: AbortSignal.timeout(5000),
      });
      if (indexRes.ok) {
        const html = await indexRes.text();
        if (indexHtmlCacheTtlMs > 0 && html) {
          if (htmlCache.size >= 10) htmlCache.clear();
          htmlCache.set(origin, {html, expiresAt: now() + indexHtmlCacheTtlMs});
        }
        return html;
      }
    } catch (_) {
      // Fall back to minimal Flutter bootstrap shell below.
    }
    return '';
  }

  return async (req, res) => {
    try {
      const origin = resolveRequestOrigin(req);
      const reqPath = typeof req.path === 'string' ?
        req.path :
        (typeof req.url === 'string' ? req.url.split('?')[0] : '');
      const horseMatch = reqPath.match(/^\/Profile\/Horse_Profile\/([^/]+)\/?$/);
      const inviteMatch = reqPath.match(/^\/invite\/([^/]+)\/?$/);

      let meta;
      let cacheControl = 'public, max-age=300, s-maxage=600';

      const dictionaryMatch = reqPath.match(/^\/Dictionary(?:\/([a-z0-9-]+))?\/?$/);
      if (inviteMatch) {
        const rawToken = safeDecodeURIComponent(inviteMatch[1]);
        const preview = await resolvePublicInvitationPreview(db, rawToken);
        const canShareRich = preview.tokenValid && preview.canRedeem;
        const inviter = preview.inviterDisplayName || 'A rider';
        const isStudent = preview.type === 'student_connection';
        meta = canShareRich ?
          {
            title: isStudent ?
              `${inviter} invited you to connect as their student — ${DEFAULT_TITLE}` :
              `${inviter} invited you to join ${DEFAULT_TITLE}`,
            description: preview.personalMessage || preview.statusMessage || DEFAULT_DESCRIPTION,
            image: preview.inviterPhotoUrl || `${origin}${DEFAULT_IMAGE_PATH}`,
            url: `${origin}/invite/${encodeURIComponent(rawToken)}`,
          } :
          {
            title: `Invitation — ${DEFAULT_TITLE}`,
            description: 'Open this link in Horse & Rider\'s Companion to view your invitation.',
            image: `${origin}${DEFAULT_IMAGE_PATH}`,
            url: `${origin}/invite`,
          };
        cacheControl = canShareRich ? 'private, max-age=60' : 'no-store';
      } else if (dictionaryMatch) {
        const entry = dictionaryMatch[1] ? await publicEntry(db, dictionaryMatch[1]) : null;
        meta = {
          title: entry ? entry.term + ' — Equestrian Dictionary — ' + DEFAULT_TITLE :
            'Equestrian Dictionary — ' + DEFAULT_TITLE,
          description: entry ? entry.definition : 'Explore plain-language equestrian definitions for every discipline.',
          image: dictionaryPreviewImage(entry, origin),
          url: origin + '/Dictionary' + (entry ? '/' + entry.slug : ''),
        };
        if (dictionaryMatch[1] && !entry) cacheControl = 'public, max-age=60, s-maxage=120';
      } else if (horseMatch) {
        const rawHorseId = safeDecodeURIComponent(horseMatch[1]);
        const horse = await resolvePublicHorse(db, rawHorseId);
        meta = buildHorsePreviewMeta(origin, horse);
        if (!horse) {
          cacheControl = 'public, max-age=60, s-maxage=120';
        }
      } else {
        const rawSkillId = req.query?.skillId || '';
        const skill = await resolvePublicSkill(db, rawSkillId);

        const canonicalPath = skill ?
          `/SkillTree?skillId=${encodeURIComponent(skill.id)}` :
          '/SkillTree';
        const subjectLabel = skill ?
          (skill.subject === 'horse' ? 'Horse Skill' : 'Rider Skill') :
          '';
        meta = skill ?
          {
            title: `${skill.name} (${subjectLabel}) — ${DEFAULT_TITLE}`,
            description: skill.summary || skill.purpose || DEFAULT_DESCRIPTION,
            image: `${origin}${DEFAULT_IMAGE_PATH}`,
            url: `${origin}${canonicalPath}`,
          } :
          {
            title: `Skill Tree — ${DEFAULT_TITLE}`,
            description: DEFAULT_DESCRIPTION,
            image: `${origin}${DEFAULT_IMAGE_PATH}`,
            url: `${origin}${canonicalPath}`,
          };
      }

      const baseHtml = await loadBaseHtml(origin);

      const html = baseHtml ?
        injectMetaIntoHtml(baseHtml, meta) :
        fallbackHtmlShell(meta);

      res.set('Content-Type', 'text/html; charset=utf-8');
      res.set('Cache-Control', cacheControl);
      res.status(200).send(html);
    } catch (err) {
      res.status(500).send(`Preview error: ${escapeHtml(err.message || err)}`);
    }
  };
}

module.exports = {
  buildMetaTagsHtml,
  escapeHtml,
  injectMetaIntoHtml,
  resolvePublicHorse,
  resolvePublicSkill,
  resolveRequestOrigin,
  sharePreviewHandler,
};
