import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHash } from 'node:crypto';
import { mkdtempSync, readFileSync, writeFileSync, readdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { ensureJar, validateManifest, validateCorpus, checkDifference } from './setup.mjs';

const pinned = JSON.parse(readFileSync(new URL('./manifest.json', import.meta.url), 'utf8'));
const corpus = JSON.parse(readFileSync(new URL('./corpus.json', import.meta.url), 'utf8'));
const fixture = Buffer.from('reviewed test artifact');
const manifest = { ...pinned, artifact: { ...pinned.artifact, sha256: createHash('sha256').update(fixture).digest('hex') } };
const temporary = t => {
  const directory = mkdtempSync(path.join(tmpdir(), 'moonspoof-icu-'));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  return directory;
};

test('pinned versions, source and checksum fields reject silent drift', () => {
  validateManifest(pinned);
  for (const change of [
    { icu_version: '77.1.0.0' }, { unicode_version: '17.0.0.0' },
    { artifact: { ...pinned.artifact, url: 'https://example.invalid/icu.jar' } },
    { artifact: { ...pinned.artifact, sha256: 'bad' } },
  ]) assert.throws(() => validateManifest({ ...pinned, ...change }));
});

test('corpus rejects empty, duplicate, malformed scalar and unreviewable entries', () => {
  validateCorpus(corpus);
  const entry = corpus.cases[0];
  for (const cases of [[], [entry, entry], [{ ...entry, input: '\uD800' }],
    [{ ...entry, repeat: 0 }], [{ ...entry, differences: { unknown: {} } }],
    [{ ...entry, differences: { skeleton: { icu: 'a', moonspoof: 'b', reason: 'ignore' } } }],
  ]) assert.throws(() => validateCorpus({ schema: 1, cases }));
});

test('valid artifact is published once and reused without a network request', async t => {
  const directory = temporary(t);
  let calls = 0;
  const fetcher = async () => { calls++; return new Response(fixture); };
  const jar = await ensureJar(directory, manifest, fetcher);
  assert.deepEqual(readFileSync(jar), fixture);
  await ensureJar(directory, manifest, fetcher);
  assert.equal(calls, 1);
  assert.deepEqual(readdirSync(directory), ['icu4j-76.1.jar']);
});

test('bad download is not cached and a valid retry succeeds', async t => {
  const directory = temporary(t);
  await assert.rejects(ensureJar(directory, manifest, async () => new Response('truncated')), /checksum mismatch/);
  assert.deepEqual(readdirSync(directory), []);
  await ensureJar(directory, manifest, async () => new Response(fixture));
  assert.deepEqual(readdirSync(directory), ['icu4j-76.1.jar']);
});

test('corrupt cache fails without network replacement', async t => {
  const directory = temporary(t);
  writeFileSync(path.join(directory, 'icu4j-76.1.jar'), 'corrupt');
  await assert.rejects(ensureJar(directory, manifest, () => assert.fail('Network must not run')), /checksum mismatch/);
  assert.equal(readFileSync(path.join(directory, 'icu4j-76.1.jar'), 'utf8'), 'corrupt');
});

test('HTTP and interrupted downloads leave no partial cache', async t => {
  const directory = temporary(t);
  await assert.rejects(ensureJar(directory, manifest, async () => new Response('', { status: 503 })), /HTTP 503/);
  await assert.rejects(ensureJar(directory, manifest, async () => { throw new Error('interrupted'); }), /interrupted/);
  assert.deepEqual(readdirSync(directory), []);
});

test('comparison fails on unreviewed, changed or stale differences', () => {
  const entry = { id: 'fixture', differences: {} };
  checkDifference(entry, 'skeleton', 'a', 'a');
  assert.throws(() => checkDifference(entry, 'skeleton', 'a', 'b'), /unreviewed/);
  entry.differences.skeleton = { icu: 'a', moonspoof: 'b', reason: 'fullwidth' };
  checkDifference(entry, 'skeleton', 'a', 'b');
  assert.throws(() => checkDifference(entry, 'skeleton', 'c', 'b'), /ICU baseline changed/);
  assert.throws(() => checkDifference(entry, 'skeleton', 'a', 'c'), /application baseline changed/);
  assert.throws(() => checkDifference(entry, 'skeleton', 'b', 'b'), /stale/);
});
