import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { ensureJar, validateCorpus, checkDifference } from './setup.mjs';
import * as engine from '../../playground/src/generated/moonspoof.js';

const directory = fileURLToPath(new URL('./', import.meta.url));
const root = path.resolve(directory, '../..');
const cache = path.join(root, '_build/icu-reference');
const read = name => readFileSync(path.join(directory, name), 'utf8');
const manifest = JSON.parse(read('manifest.json'));
const sourceManifest = JSON.parse(readFileSync(path.join(root, 'tools/data-generator/sources.json'), 'utf8'));
assert.equal(manifest.unicode_version, `${sourceManifest.unicode_version}.0`, 'Library/reference data versions differ');
const corpusText = read('corpus.json');
const corpus = validateCorpus(JSON.parse(corpusText));
const jar = await ensureJar(cache, manifest);
const run = (command, args, input) => {
  const result = spawnSync(command, args, { cwd: root, input, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 });
  if (result.error) throw new Error(`${command} is required for optional ICU verification`, { cause: result.error });
  assert.equal(result.status, 0, `${command} failed:\n${result.stderr}`);
  return result.stdout;
};
run('javac', ['-encoding', 'UTF-8', '-cp', jar, '-d', cache, path.join(directory, 'IcuReference.java')]);
const inputs = corpus.cases.map(entry => entry.input.repeat(entry.repeat ?? 1));
const protocol = inputs.map(input => Buffer.from(input).toString('base64')).join('\n') + '\n';
const output = run('java', ['-cp', `${cache}${path.delimiter}${jar}`, 'IcuReference'], protocol)
  .trim().split(/\r?\n/).map(line => JSON.parse(line));
const metadata = output.shift();
assert.equal(metadata.icu, manifest.icu_version, 'Unexpected ICU runtime');
assert.equal(metadata.unicode, manifest.unicode_version, 'Unexpected Unicode runtime');
assert.equal(output.length, corpus.cases.length, 'Incomplete reference output');

const decode = value => Buffer.from(value, 'base64').toString('utf8');
const differences = [];
const failures = [];
let exactAssertions = 0;
let propertyAssertions = 0;
let reviewedDifferences = 0;
for (let i = 0; i < corpus.cases.length; i++) {
  const entry = corpus.cases[i];
  const text = inputs[i];
  const reference = output[i];
  const skeleton = engine.spoof_skeleton(text);
  const folded = engine.spoof_skeleton_case_folded(text);
  assert.equal(engine.spoof_normalize_nfd(text), decode(reference.nfd), `${entry.id}: NFD`);
  assert.equal(skeleton, decode(reference.applicationSkeleton), `${entry.id}: ICU with documented key extensions`);
  assert.equal(folded, decode(reference.applicationFolded), `${entry.id}: ICU with documented folded extensions`);
  assert.deepEqual(JSON.parse(engine.spoof_decimal_systems(text)), reference.decimalSystems, `${entry.id}: decimal representatives`);
  assert.equal(Boolean(engine.spoof_has_mixed_numbers(text)), reference.mixedNumbers, `${entry.id}: mixed numbers`);
  exactAssertions += 5;
  for (const [cp, script, extensions, allowed, zero] of reference.properties) {
    assert.equal(engine.spoof_unicode_script(cp), script, `${entry.id}: Script U+${cp.toString(16)}`);
    assert.deepEqual(JSON.parse(engine.spoof_script_extensions(cp)), extensions, `${entry.id}: Script_Extensions U+${cp.toString(16)}`);
    assert.equal(Boolean(engine.spoof_identifier_status_allowed(cp)), allowed, `${entry.id}: Identifier_Status U+${cp.toString(16)}`);
    assert.equal(engine.spoof_decimal_zero(cp), zero, `${entry.id}: decimal zero U+${cp.toString(16)}`);
    propertyAssertions += 4;
  }
  for (const field of ['skeleton', 'foldedSkeleton', 'bidiLtrSkeleton']) {
    const icu = decode(reference[field]);
    const moonspoof = field === 'foldedSkeleton' ? folded : skeleton;
    if (icu !== moonspoof) differences.push({ id: entry.id, field, icu, moonspoof, reason: entry.differences[field]?.reason ?? null });
    try {
      checkDifference(entry, field, icu, moonspoof);
      if (icu !== moonspoof) reviewedDifferences++;
    } catch (error) {
      failures.push({ id: entry.id, field, message: error.message });
    }
  }
}
const report = {
  ...metadata,
  corpusSha256: createHash('sha256').update(corpusText).digest('hex'),
  cases: corpus.cases.length, exactAssertions, propertyAssertions,
  rawComparisons: corpus.cases.length * 3,
  observedDifferences: differences.length,
  reviewedDifferences,
  differences, failures,
};
const reportFile = path.join(cache, 'report.json');
writeFileSync(reportFile, JSON.stringify(report, null, 2) + '\n');
assert.equal(failures.length, 0, `Unreviewed or changed reference behavior; inspect ${reportFile}`);
console.log(JSON.stringify({ ...report, differences: undefined, failures: undefined, report: reportFile }, null, 2));
