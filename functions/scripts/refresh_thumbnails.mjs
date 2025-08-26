// Run with Node 18+
// Usage:
//   RESOLVE_ENDPOINT="https://us-central1-<project>.cloudfunctions.net/resolveImage" \
//   GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json" \
//   node functions/scripts/refresh_thumbnails.mjs --project <your-project-id> [--force] [--only <docId>]

import admin from 'firebase-admin';

const args = new Map(
  process.argv.slice(2).map((a, i, arr) =>
    a.startsWith('--') ? [a.replace(/^--/, ''), arr[i + 1] && !arr[i + 1].startsWith('--') ? arr[i + 1] : 'true'] : null
  ).filter(Boolean)
);

const PROJECT = args.get('project') || process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT;
const ONLY_ID = args.get('only') || null;
const FORCE = args.get('force') === 'true';

const RESOLVE_ENDPOINT = process.env.RESOLVE_ENDPOINT; // REQUIRED
if (!RESOLVE_ENDPOINT) {
  console.error('Missing RESOLVE_ENDPOINT env var (your deployed resolveImage URL)');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: PROJECT,
});
const db = admin.firestore();

async function resolveFor(url, hint) {
  const r = await fetch(RESOLVE_ENDPOINT, {
    method: 'POST',
    headers: {'content-type': 'application/json'},
    body: JSON.stringify({url, hint}),
  });
  if (!r.ok) {
    const t = await r.text().catch(() => '');
    throw new Error(`resolveImage ${r.status}: ${t || 'HTTP error'}`);
  }
  return r.json(); // { resolvedUrl?, proxiedUrl? }
}

function isProxied(u) {
  return typeof u === 'string' && (u.startsWith('https://wsrv.nl/?url=') || u.startsWith('https://i0.wp.com/') || u.startsWith('https://i1.wp.com/') || u.startsWith('https://i2.wp.com/'));
}

async function refreshDoc(doc) {
  const data = doc.data() || {};
  const type = data.type;                  // 'link' | 'article' | 'pdf' ...
  const url = data.url;
  const thumb = data.thumbnail;

  if (!url || typeof url !== 'string') return {skipped: 'no-url'};
  if (type && String(type).toLowerCase() === 'pdf') return {skipped: 'pdf'};
  if (!FORCE && isProxied(thumb)) return {skipped: 'already-proxied'};

  try {
    const out = await resolveFor(url, thumb);
    const nextThumb = out.proxiedUrl || out.resolvedUrl;
    if (!nextThumb) return {skipped: 'resolver-empty'};

    await doc.ref.update({
      thumbnail: nextThumb,
      thumbnailResolved: out.resolvedUrl || null,
      thumbnailProxied: out.proxiedUrl || null,
      thumbnailCheckedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return {updated: true};
  } catch (e) {
    return {error: String(e)};
  }
}

async function main() {
  let count = 0, updated = 0, skipped = 0, errored = 0;

  if (ONLY_ID) {
    const ref = db.collection('Resources').doc(ONLY_ID);
    const snap = await ref.get();
    if (!snap.exists) throw new Error(`Doc not found: ${ONLY_ID}`);
    const res = await refreshDoc(snap);
    console.log(ONLY_ID, res);
    process.exit(0);
  }

  let q = db.collection('Resources').orderBy(admin.firestore.FieldPath.documentId()).limit(200);
  for (;;) {
    const snap = await q.get();
    if (snap.empty) break;

    for (const d of snap.docs) {
      count++;
      const res = await refreshDoc(d);
      if (res.updated) updated++;
      else if (res.error) { errored++; console.warn(d.id, res); }
      else { skipped++; }
    }

    const last = snap.docs[snap.docs.length - 1];
    q = db.collection('Resources')
      .orderBy(admin.firestore.FieldPath.documentId())
      .startAfter(last.id)
      .limit(200);
  }

  console.log(JSON.stringify({count, updated, skipped, errored}, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
