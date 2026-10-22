import assert from 'node:assert/strict';
import { createHash, randomUUID } from 'node:crypto';
import { existsSync, readFileSync, mkdirSync, writeFileSync, renameSync, rmSync } from 'node:fs';
import path from 'node:path';

export function validateManifest(manifest) {
  assert.equal(manifest?.icu_version, '76.1.0.0', 'Review ICU version changes explicitly');
  assert.equal(manifest?.unicode_version, '16.0.0.0', 'Reference Unicode must match the library');
  assert.equal(manifest?.artifact?.url,
    'https://repo.maven.apache.org/maven2/com/ibm/icu/icu4j/76.1/icu4j-76.1.jar');
  assert.match(manifest.artifact.sha256, /^[a-f0-9]{64}$/);
  return manifest;
}

export async function ensureJar(directory, manifest, fetcher = fetch) {
  validateManifest(manifest);
  const destination = path.join(directory, 'icu4j-76.1.jar');
  const verify = bytes => assert.equal(createHash('sha256').update(bytes).digest('hex'),
    manifest.artifact.sha256, 'ICU artifact checksum mismatch; restore the pinned artifact');
  if (existsSync(destination)) {
    verify(readFileSync(destination));
    return destination;
  }
  const response = await fetcher(manifest.artifact.url, { signal: AbortSignal.timeout(60000) });
  assert(response.ok, `ICU download failed: HTTP ${response.status}`);
  const bytes = Buffer.from(await response.arrayBuffer());
  verify(bytes);
  mkdirSync(directory, { recursive: true });
  const temporary = `${destination}.${randomUUID()}.tmp`;
  try {
    writeFileSync(temporary, bytes, { flag: 'wx' });
    renameSync(temporary, destination);
  } finally {
    rmSync(temporary, { force: true });
  }
  return destination;
}

const fields = ['skeleton', 'foldedSkeleton', 'bidiLtrSkeleton'];
const reasons = ['fullwidth', 'stable-key', 'fold-policy', 'bidi-deferred'];

export function validateCorpus(corpus) {
  assert.equal(corpus?.schema, 1);
  assert(Array.isArray(corpus.cases) && corpus.cases.length > 0, 'Empty reference corpus');
  const ids = new Set();
  for (const entry of corpus.cases) {
    assert.match(entry.id, /^[a-z0-9-]+$/);
    assert(!ids.has(entry.id), `Duplicate corpus id: ${entry.id}`);
    ids.add(entry.id);
    assert.equal(typeof entry.input, 'string');
    assert(entry.input.isWellFormed(), `Invalid scalar in ${entry.id}`);
    assert(Number.isInteger(entry.repeat ?? 1) && (entry.repeat ?? 1) > 0 && (entry.repeat ?? 1) <= 1024);
    assert(entry.differences && typeof entry.differences === 'object' && !Array.isArray(entry.differences));
    for (const [field, difference] of Object.entries(entry.differences)) {
      assert(fields.includes(field), `Unknown comparison: ${field}`);
      assert(reasons.includes(difference.reason), `Unknown explanation: ${difference.reason}`);
      assert.equal(typeof difference.icu, 'string');
      assert.equal(typeof difference.moonspoof, 'string');
      assert.notEqual(difference.icu, difference.moonspoof, 'A difference must differ');
    }
  }
  return corpus;
}

export function checkDifference(entry, field, icu, moonspoof) {
  const difference = entry.differences[field];
  if (!difference) {
    assert.equal(moonspoof, icu, `${entry.id}: unreviewed ${field} difference`);
  } else {
    assert.notEqual(moonspoof, icu, `${entry.id}: stale difference annotation`);
    assert.equal(icu, difference.icu, `${entry.id}: ICU baseline changed`);
    assert.equal(moonspoof, difference.moonspoof, `${entry.id}: application baseline changed`);
  }
}
