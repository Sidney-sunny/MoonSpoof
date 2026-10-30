import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const output = path.join(root, 'playground/dist');
const engineInfo = readFileSync(path.join(root, 'playground/src/generated/build-info.json'));
assert.deepEqual(readFileSync(path.join(output, 'build-info.json')), engineInfo, 'Site/engine build metadata differ');
const metadata = JSON.parse(engineInfo.toString('utf8'));
const files = {};
function visit(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name, 'en'))) {
    const full = path.join(directory, entry.name);
    assert(!entry.isSymbolicLink(), `Unexpected site symlink: ${full}`);
    if (entry.isDirectory()) visit(full);
    else {
      assert(entry.isFile(), `Unexpected site entry: ${full}`);
      const relative = path.relative(output, full).split(path.sep).join('/');
      if (relative !== 'site-files.json') files[relative] = createHash('sha256').update(readFileSync(full)).digest('hex');
    }
  }
}
visit(output);
assert(files['index.html'] && files['build-info.json'], 'Incomplete site output');
writeFileSync(path.join(output, 'site-files.json'), JSON.stringify({ schema: 1, commit: metadata.commit, files }, null, 2) + '\n');
console.log(`Stamped ${Object.keys(files).length} site files for commit ${metadata.commit}`);
