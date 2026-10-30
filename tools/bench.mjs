import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { arch, availableParallelism, cpus, platform, release, totalmem } from 'node:os';
import { performance } from 'node:perf_hooks';
import { fileURLToPath } from 'node:url';
import {
  spoof_analyze,
  spoof_batch_scan_with_options,
  spoof_compare,
  spoof_skeleton,
  spoof_skeleton_case_folded,
} from '../playground/src/generated/moonspoof.js';
import { batchCorpus, keyCorpus, sha256, summarizeCorpus } from './benchmark-fixtures.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const args = process.argv.slice(2);
const checkOnly = args.length === 1 && args[0] === '--check-fixtures';
const output = args.length === 2 && args[0] === '--output' ? args[1] : undefined;
if (args.length > 0 && !checkOnly && output === undefined) {
  throw new Error('Usage: node tools/bench.mjs [--check-fixtures | --output path]');
}

const rounds = 5;
const warmupLimit = 1000;
const keyIterations = 1000;
const batchIterations = 20;
const comparisonCorpus = ['paypal', 'p\u0430ypal'];
const diagnosticCorpus = ['p\u0430ypal_service\u200B'];
const batches = [1000, 10000].map(batchCorpus);
const keyPolicies = [
  { name: 'sensitive', ignoreCase: false, key: spoof_skeleton },
  { name: 'folded', ignoreCase: true, key: spoof_skeleton_case_folded },
];

function canonicalGroups(groups) {
  return groups.map(({ skeleton, members }) => [skeleton, [...members].sort()])
    .sort(([a], [b]) => a < b ? -1 : a > b ? 1 : 0);
}

// Check fixture semantics and batch serialization before timing either path.
assert.equal(spoof_skeleton('p\u0430ypal'), spoof_skeleton('paypal'));
assert.notEqual(spoof_skeleton('A'), spoof_skeleton('a'));
assert.equal(spoof_skeleton_case_folded('A'), spoof_skeleton_case_folded('a'));
assert.equal(spoof_skeleton('\u00E9'), spoof_skeleton('e\u0301'));
const batchMetadata = [];
for (const batch of batches) {
  assert.equal(new Set(batch.names).size, batch.names.length, 'Batch fixtures contain no exact duplicates');
  const policies = {};
  for (const policy of keyPolicies) {
    const expected = new Map();
    for (const name of batch.names) {
      const key = policy.key(name);
      if (!expected.has(key)) expected.set(key, []);
      expected.get(key).push(name);
    }
    const groups = [...expected].filter(([, members]) => members.length > 1)
      .map(([skeleton, members]) => ({ skeleton, members }));
    const actual = JSON.parse(spoof_batch_scan_with_options(batch.raw, policy.ignoreCase));
    assert.equal(actual.total_names, batch.names.length);
    assert.equal(actual.ignore_case, policy.ignoreCase);
    assert.equal(actual.group_count, groups.length);
    assert.deepEqual(canonicalGroups(actual.groups), canonicalGroups(groups));
    for (const group of actual.groups) assert.equal(group.count, group.members.length);
    policies[policy.name] = {
      collisionGroups: groups.length,
      collidingNames: groups.reduce((count, group) => count + group.members.length, 0),
      outputSha256: sha256(JSON.stringify(canonicalGroups(actual.groups))),
    };
  }
  batchMetadata.push({ ...summarizeCorpus(batch.names, batch.raw), exactDuplicates: 0, policies });
}

if (checkOnly) {
  console.log(JSON.stringify({ keyCorpus: summarizeCorpus(keyCorpus), batches: batchMetadata }, null, 2));
  process.exit(0);
}

function command(program, arguments_) {
  return execFileSync(program, arguments_, {
    cwd: root, encoding: 'utf8', shell: process.platform === 'win32',
  }).trim();
}

const pinnedCompiler = readFileSync(new URL('../.moon-version', import.meta.url), 'utf8').trim();
const moonc = command('moonc', ['-v']);
assert.ok(moonc.startsWith(`v${pinnedCompiler} `), `Expected compiler ${pinnedCompiler}; got ${moonc}`);
const trackedPaths = new Set(command('git', ['ls-files']).split(/\r?\n/));
const sourcePaths = [...new Set(command('git', ['ls-files', '--cached', '--others', '--exclude-standard']).split(/\r?\n/))]
  .filter(name => /\.mbt$|\.pkg$/.test(name) || name === 'moon.mod' || name === '.moon-version')
  .sort();
const untrackedSourceFiles = sourcePaths.filter(name => !trackedPaths.has(name));
const sourceHash = createHash('sha256');
for (const source of sourcePaths) {
  sourceHash.update(`${source}\0${sha256(readFileSync(new URL(`../${source}`, import.meta.url)))}\n`);
}
let sourceDiffersFromRevision = untrackedSourceFiles.length > 0;
try {
  command('git', ['diff', '--quiet', 'HEAD', '--', ...sourcePaths]);
} catch (error) {
  if (error.status !== 1) throw error;
  sourceDiffersFromRevision = true;
}
const sources = JSON.parse(readFileSync(new URL('./data-generator/sources.json', import.meta.url), 'utf8'));
const moduleText = readFileSync(new URL('../moon.mod', import.meta.url), 'utf8');
const sourceRevision = command('git', ['rev-parse', 'HEAD']);
const engineFile = new URL('../playground/src/generated/moonspoof.js', import.meta.url);
const engineSha256 = sha256(readFileSync(engineFile));
const date = new Date().toISOString();

// Return and check a consumed result every iteration; setup and preflight are untimed.
function measure(name, iterations, operation, unitsPerOperation = 1, unit = 'call') {
  const expected = operation();
  const warmupIterations = Math.min(iterations, warmupLimit);
  let warmupGuard = 0;
  for (let i = 0; i < warmupIterations; i++) warmupGuard += operation();
  assert.equal(warmupGuard, expected * warmupIterations);
  const samples = [];
  const consumedResults = [];
  for (let round = 0; round < rounds; round++) {
    let guard = 0;
    const start = performance.now();
    for (let i = 0; i < iterations; i++) guard += operation();
    samples.push(performance.now() - start);
    assert.equal(guard, expected * iterations, 'Benchmark operation changed its result');
    consumedResults.push(guard);
  }
  const sorted = [...samples].sort((a, b) => a - b);
  const milliseconds = sorted[Math.floor(rounds / 2)];
  return {
    name, iterations, unitsPerOperation, unit, warmupIterations, rounds,
    unitsPerRound: iterations * unitsPerOperation,
    roundMilliseconds: samples.map(value => +value.toFixed(4)),
    medianMilliseconds: +milliseconds.toFixed(4),
    microsecondsPerOperation: +(milliseconds * 1000 / iterations).toFixed(4),
    microsecondsPerUnit: +(milliseconds * 1000 / iterations / unitsPerOperation).toFixed(4),
    unitsPerSecond: Math.round(iterations * unitsPerOperation * 1000 / milliseconds),
    rangeMilliseconds: [+sorted[0].toFixed(4), +sorted.at(-1).toFixed(4)],
    consumedResults,
  };
}

const results = [];
for (const policy of keyPolicies) {
  const keys = keyCorpus.map(policy.key);
  results.push({
    ...measure(`key_generation_${policy.name}`, keyIterations, () => {
      let length = 0;
      for (const name of keyCorpus) length += policy.key(name).length;
      return length;
    }, keyCorpus.length, 'identifier'),
    keyPolicy: policy.name,
    outputSha256: sha256(JSON.stringify(keys)),
  });
}
for (const [index, batch] of batches.entries()) {
  for (const policy of keyPolicies) {
    results.push({
      ...measure(`batch_${policy.name}_${batch.names.length}`, batchIterations, () => {
        const report = JSON.parse(spoof_batch_scan_with_options(batch.raw, policy.ignoreCase));
        return report.total_names + report.group_count;
      }, batch.names.length, 'identifier'),
      keyPolicy: policy.name,
      collisionGroups: batchMetadata[index].policies[policy.name].collisionGroups,
    });
  }
}
results.push(measure('compare_paypal_confusable', 10000, () => spoof_compare(...comparisonCorpus).length));
results.push(measure('analyze_cyrillic_zwsp', 10000, () => spoof_analyze(diagnosticCorpus[0]).length));
assert.equal(sha256(readFileSync(engineFile)), engineSha256, 'Engine changed during measurement');

const report = {
  schemaVersion: 2,
  date,
  environment: {
    moonc,
    moon: command('moon', ['version']),
    pinnedCompiler,
    node: process.version,
    nodeOptions: process.env.NODE_OPTIONS ?? '',
    nodeArguments: process.execArgv,
    os: platform(),
    osRelease: release(),
    architecture: arch(),
    cpu: cpus()[0]?.model ?? 'unknown',
    logicalCpus: cpus().length,
    availableParallelism: availableParallelism(),
    totalMemoryBytes: totalmem(),
  },
  provenance: {
    sourceRevision,
    sourceDiffersFromRevision,
    moduleVersion: /^version\s*=\s*"([^"]+)"/m.exec(moduleText)?.[1] ?? 'unknown',
    sourceFileCount: sourcePaths.length,
    untrackedSourceFiles,
    sourceSha256: sourceHash.digest('hex'),
    sourceHashFormat: 'SHA256 of sorted tracked and untracked non-ignored MoonBit/package paths: path + NUL + SHA256(file bytes) + LF',
    engineSha256,
    benchmarkScriptSha256: sha256(readFileSync(new URL(import.meta.url))),
    fixtureScriptSha256: sha256(readFileSync(new URL('./benchmark-fixtures.mjs', import.meta.url))),
    unicodeVersion: sources.unicode_version,
    unicodeManifestSha256: sha256(readFileSync(new URL('./data-generator/sources.json', import.meta.url))),
  },
  method: {
    target: 'MoonBit release JavaScript; direct string key API and JSON batch/report ABI',
    timing: 'Monotonic performance.now; five sequential rounds per case; median round duration',
    keyGeneration: '32 fixed multilingual identifiers per iteration; direct key output length consumed; no report or JSON creation',
    batch: 'Unique deterministic input names; line parsing, key generation, hash grouping, JSON serialization and JSON.parse included',
    reports: 'Comparison and diagnostics include report construction and JSON serialization; JSON.parse excluded',
    excluded: ['engine build', 'fixture construction', 'correctness preflight', 'worker transport', 'DOM/rendering', 'network/disk I/O'],
    limitations: 'Single host and process; GC and scheduling included; no cross-runtime ranking, latency guarantee or confidence interval',
  },
  corpora: {
    keys: { ...summarizeCorpus(keyCorpus), names: keyCorpus },
    comparison: { ...summarizeCorpus(comparisonCorpus), names: comparisonCorpus },
    diagnostics: { ...summarizeCorpus(diagnosticCorpus), names: diagnosticCorpus },
    batches: batchMetadata,
    batchGenerator: 'tools/benchmark-fixtures.mjs: ten templates per numbered cluster; no exact duplicate names',
  },
  results,
};
const serialized = `${JSON.stringify(report, null, 2)}\n`;
if (output !== undefined) writeFileSync(output, serialized);
console.log(serialized.trimEnd());
