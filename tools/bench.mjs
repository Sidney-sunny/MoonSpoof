import { performance } from 'node:perf_hooks';
import { cpus, platform, arch } from 'node:os';
import { execFileSync } from 'node:child_process';
import { spoof_compare, spoof_analyze, spoof_batch_scan } from '../playground/src/generated/moonspoof.js';

// Measure the actual JSON ABI, not only the core algorithm; no competitor ranking.
function measure(name, iterations, operation, unitsPerOperation = 1) {
  for (let i = 0; i < Math.min(iterations, 1000); i++) operation();
  const samples = [];
  for (let round = 0; round < 5; round++) {
    const start = performance.now();
    for (let i = 0; i < iterations; i++) operation();
    samples.push(performance.now() - start);
  }
  samples.sort((a, b) => a - b);
  const milliseconds = samples[2];
  return { name, iterations, unitsPerOperation, rounds: 5, medianMilliseconds: +milliseconds.toFixed(2), microsecondsPerOperation: +(milliseconds * 1000 / iterations).toFixed(2), unitsPerSecond: Math.round(iterations * unitsPerOperation * 1000 / milliseconds), rangeMilliseconds: [+samples[0].toFixed(2), +samples[4].toFixed(2)] };
}

function batchInput(count) {
  return Array.from({ length: count }, (_, i) => i % 5 === 0 ? `p\u0430ypal_${i % 200}` : i % 7 === 0 ? `admin\u200B_${i % 200}` : `user_${i}`).join('\n');
}
const batches = [1000, 10000].map(count => [count, batchInput(count)]);
const compiler = execFileSync('moon', ['version'], { encoding: 'utf8', shell: process.platform === 'win32' }).trim();
console.log(JSON.stringify({
  date: new Date().toISOString(),
  environment: { compiler, node: process.version, os: platform(), architecture: arch(), cpu: cpus()[0].model },
  target: 'MoonBit release JavaScript JSON ABI; worker transport and DOM excluded',
  results: [
    measure('spoof_compare(paypal, pаypal)', 10000, () => spoof_compare('paypal', 'p\u0430ypal')),
    ...batches.map(([count, raw]) => ({ ...measure(`spoof_batch_scan(${count})`, 20, () => JSON.parse(spoof_batch_scan(raw)), count), collisionGroups: JSON.parse(spoof_batch_scan(raw)).group_count })),
    measure('spoof_analyze(pаypal_service+ZWSP)', 10000, () => spoof_analyze('p\u0430ypal_service\u200B')),
  ],
}, null, 2));
