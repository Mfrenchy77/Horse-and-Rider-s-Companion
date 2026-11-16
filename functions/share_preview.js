/* eslint-disable require-jsdoc */
/* eslint max-len: ["error", {"code": 120}] */
'use strict';

const DEFAULT_TITLE = 'Horse & Rider\'s Companion';
const DEFAULT_DESCRIPTION =
  'Track Rider and Horse horsemanship skills, explore Skill Tree 2.0, and share educational resources.';
const DEFAULT_IMAGE_PATH = '/icons/Icon-512.png';
const PROD_ORIGIN = 'https://horse-and-riders-compani-d2bd4.web.app';
const DOC_ID_REGEX = /^[A-Za-z0-9._-]{1,120}$/;

function escapeHtml(value) {
  return String(value || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
}

function resolveRequestOrigin(req) {
  const forwardedHost = (req.headers['x-forwarded-host'] || '').split(',')[0].trim();
  const host = forwardedHost || (req.headers.host || '').trim();
  if (!host) return PROD_ORIGIN;
  const forwardedProto = (req.headers['x-forwarded-proto'] || '').split(',')[0].trim();
  const isLocal = host.startsWith('127.0.0.1') || host.startsWith('localhost');
  const proto = forwardedProto || (isLocal ? 'http' : 'https');
  return `${proto}://${host}`;
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

function sharePreviewHandler(db, {fetchFn = fetch} = {}) {
  return async (req, res) => {
    try {
      const origin = resolveRequestOrigin(req);
      const rawSkillId = req.query?.skillId || '';
      const skill = await resolvePublicSkill(db, rawSkillId);

      const canonicalPath = skill ?
        `/SkillTree?skillId=${encodeURIComponent(skill.id)}` :
        '/SkillTree';
      const subjectLabel = skill ?
        (skill.subject === 'horse' ? 'Horse Skill' : 'Rider Skill') :
        '';
      const meta = skill ?
        {
          title: `${skill.name} (${subjectLabel}) — ${DEFAULT_TITLE}`,
          description: skill.summary || skill.purpose || DEFAULT_DESCRIPTION,
          image: `${origin}${DEFAULT_IMAGE_PATH}`,
          url: `${origin}${canonicalPath}`,
        } :
        {
          title: `Skill Tree 2.0 — ${DEFAULT_TITLE}`,
          description: DEFAULT_DESCRIPTION,
          image: `${origin}${DEFAULT_IMAGE_PATH}`,
          url: `${origin}${canonicalPath}`,
        };

      let baseHtml = '';
      try {
        const indexRes = await fetchFn(`${origin}/index.html`, {redirect: 'follow'});
        if (indexRes.ok) {
          baseHtml = await indexRes.text();
        }
      } catch (_) {
        // Fall back to minimal Flutter bootstrap shell below.
      }

      const html = baseHtml ?
        injectMetaIntoHtml(baseHtml, meta) :
        fallbackHtmlShell(meta);

      res.set('Content-Type', 'text/html; charset=utf-8');
      res.set('Cache-Control', 'public, max-age=300, s-maxage=600');
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
  resolvePublicSkill,
  resolveRequestOrigin,
  sharePreviewHandler,
};
