import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { parseNormalizationVectors } from './normalization-vectors.mjs';
import { verifyUnicodeProperties } from './verify-properties.mjs';
import * as engine from '../playground/src/generated/moonspoof.js';

const directory = fileURLToPath(new URL('./data-generator/', import.meta.url));
const manifest = JSON.parse(readFileSync(path.join(directory, 'sources.json'), 'utf8'));
for (const [name, { sha256 }] of Object.entries(manifest.sources)) {
  const file = path.join(directory, name);
  if (!existsSync(file)) throw new Error('Run python tools/data-generator/generate.py before Unicode verification.');
  assert.equal(createHash('sha256').update(readFileSync(file)).digest('hex'), sha256, `Source checksum: ${name}`);
}
const vectors = parseNormalizationVectors(readFileSync(path.join(directory, 'NormalizationTest.txt'), 'utf8'));
for (const [c1, c2, c3, c4, c5] of vectors) {
  for (const text of [c1, c2, c3]) assert.equal(engine.spoof_normalize_nfd(text), c3, 'Unicode NFD invariant c1/c2/c3');
  for (const text of [c4, c5]) assert.equal(engine.spoof_normalize_nfd(text), c5, 'Unicode NFD invariant c4/c5');
}

const codepoints = new Set();
const confusables = new Map();
const ignorables = [];
for (const line of readFileSync(path.join(directory, 'DerivedCoreProperties.txt'), 'utf8').split('\n')) {
  const fields = line.split('#')[0].trim().split(';');
  if (fields[1]?.trim() !== 'Default_Ignorable_Code_Point') continue;
  const bounds = fields[0].trim().split('..').map(hex => Number.parseInt(hex, 16));
  ignorables.push([bounds[0], bounds.at(-1)]);
}
let mappings = 0;
for (const line of readFileSync(path.join(directory, 'confusables.txt'), 'utf8').split('\n')) {
  const fields = line.split('#')[0].trim().split(';');
  if (fields.length < 3) continue;
  const cp = Number.parseInt(fields[0], 16);
  const target = fields[1].trim().split(/\s+/).map(hex => String.fromCodePoint(Number.parseInt(hex, 16))).join('');
  codepoints.add(cp);
  confusables.set(cp, target);
}
function referenceSkeleton(text) {
  let current = engine.spoof_normalize_nfd(text);
  for (let iteration = 0; iteration < 8; iteration++) {
    const mapped = [...current].map(char => {
      let cp = char.codePointAt(0);
      if (ignorables.some(([start, end]) => cp >= start && cp <= end)) return '';
      if (cp === 0x3000) cp = 0x20;
      else if (cp >= 0xFF01 && cp <= 0xFF5E) cp -= 0xFEE0;
      return confusables.get(cp) ?? String.fromCodePoint(cp);
    }).join('');
    const next = engine.spoof_normalize_nfd(mapped);
    if (next === current) return next;
    current = next;
  }
  throw new Error('Reference skeleton did not converge.');
}
for (const cp of codepoints) {
  const source = String.fromCodePoint(cp);
  // NFD precedes lookup: a decomposable source does not use its raw table row.
  assert.equal(engine.spoof_skeleton(source), referenceSkeleton(source), `Confusable pipeline U+${cp.toString(16)}`);
  mappings++;
}
let folds = 0;
for (const line of readFileSync(path.join(directory, 'CaseFolding.txt'), 'utf8').split('\n')) {
  const fields = line.split('#')[0].trim().split(';');
  if (fields.length < 3 || !['C', 'F'].includes(fields[1].trim())) continue;
  const cp = Number.parseInt(fields[0], 16);
  const target = fields[2].trim().split(/\s+/).map(hex => String.fromCodePoint(Number.parseInt(hex, 16))).join('');
  codepoints.add(cp);
  assert.equal(engine.spoof_skeleton_case_folded(String.fromCodePoint(cp)), engine.spoof_skeleton_case_folded(target), `Case folding U+${cp.toString(16)}`);
  folds++;
}
for (const cp of codepoints) {
  const text = String.fromCodePoint(cp);
  const key = engine.spoof_skeleton_case_folded(text);
  assert.equal(engine.spoof_skeleton_case_folded(key), key, `Folded key stability U+${cp.toString(16)}`);
  const skeleton = engine.spoof_skeleton(text);
  assert.equal(engine.spoof_skeleton(skeleton), skeleton, `Skeleton stability U+${cp.toString(16)}`);
}
const properties = verifyUnicodeProperties(engine, directory);
console.log(JSON.stringify({ unicode: manifest.unicode_version, normalizationVectors: vectors.length, normalizationAssertions: vectors.length * 5, confusableMappings: mappings, caseFoldMappings: folds, stableCodepoints: codepoints.size, sourceChecksums: Object.keys(manifest.sources).length, ...properties }, null, 2));
