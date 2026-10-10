import { spoof_compare, spoof_analyze, spoof_batch_scan } from '../playground/src/moonspoof.js';

async function main() {
  console.log('----------------------------------------------------');
  console.log('MoonSpoof Engine Performance & Throughput Benchmark');
  console.log('----------------------------------------------------');

  // 1. Single pair comparison throughput
  const N_COMPARE = 50000;
  const t0 = performance.now();
  for (let i = 0; i < N_COMPARE; i++) {
    spoof_compare('paypal', 'p\u0430ypal');
  }
  const dtCompare = performance.now() - t0;
  const opsSec = (N_COMPARE / (dtCompare / 1000)).toFixed(0);
  const latencyUs = ((dtCompare / N_COMPARE) * 1000).toFixed(2);
  console.log(`Single Pair Comparison:`);
  console.log(`  Iterations: ${N_COMPARE}`);
  console.log(`  Total time: ${dtCompare.toFixed(2)} ms`);
  console.log(`  Throughput: ${opsSec} ops/sec`);
  console.log(`  Latency:    ${latencyUs} µs/op`);
  console.log('');

  // 2. Batch collision scan: 1,000 items
  const items1k = [];
  for (let i = 0; i < 1000; i++) {
    if (i % 5 === 0) items1k.push('p\u0430ypal_' + (i % 50));
    else if (i % 7 === 0) items1k.push('admin\u200B_' + (i % 50));
    else items1k.push('user_' + i);
  }
  const raw1k = items1k.join('\n');
  const t1 = performance.now();
  const res1k = JSON.parse(spoof_batch_scan(raw1k));
  const dt1k = performance.now() - t1;
  console.log(`Batch Collision Scan (1,000 Identifiers):`);
  console.log(`  Total names:      ${res1k.total_names}`);
  console.log(`  Collision groups: ${res1k.group_count}`);
  console.log(`  Execution time:   ${dt1k.toFixed(2)} ms`);
  console.log(`  Rate:             ${((1000 / dt1k) * 1000).toFixed(0)} names/sec`);
  console.log('');

  // 3. Batch collision scan: 10,000 items
  const items10k = [];
  for (let i = 0; i < 10000; i++) {
    if (i % 5 === 0) items10k.push('p\u0430ypal_' + (i % 200));
    else if (i % 7 === 0) items10k.push('admin\u200B_' + (i % 200));
    else items10k.push('user_' + i);
  }
  const raw10k = items10k.join('\n');
  const t2 = performance.now();
  const res10k = JSON.parse(spoof_batch_scan(raw10k));
  const dt10k = performance.now() - t2;
  console.log(`Batch Collision Scan (10,000 Identifiers):`);
  console.log(`  Total names:      ${res10k.total_names}`);
  console.log(`  Collision groups: ${res10k.group_count}`);
  console.log(`  Execution time:   ${dt10k.toFixed(2)} ms`);
  console.log(`  Rate:             ${((10000 / dt10k) * 1000).toFixed(0)} names/sec`);
  console.log('');

  // 4. Character diagnostic audit throughput
  const N_ANALYZE = 20000;
  const t3 = performance.now();
  for (let i = 0; i < N_ANALYZE; i++) {
    spoof_analyze('p\u0430ypal_service\u200B');
  }
  const dtAnalyze = performance.now() - t3;
  const analyzeOps = (N_ANALYZE / (dtAnalyze / 1000)).toFixed(0);
  const analyzeLat = ((dtAnalyze / N_ANALYZE) * 1000).toFixed(2);
  console.log(`Character Diagnostic Audit:`);
  console.log(`  Iterations: ${N_ANALYZE}`);
  console.log(`  Total time: ${dtAnalyze.toFixed(2)} ms`);
  console.log(`  Throughput: ${analyzeOps} ops/sec`);
  console.log(`  Latency:    ${analyzeLat} µs/op`);
  console.log('----------------------------------------------------');
}

main();
