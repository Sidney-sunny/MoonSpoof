import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const build = spawnSync('moon', ['build', 'src/bindings/web', '--target', 'js', '--release'], {
  cwd: root, stdio: 'inherit', shell: process.platform === 'win32',
});
if (build.error) throw build.error;
if (build.status !== 0) process.exit(build.status ?? 1);
const destination = path.join(root, 'playground/src/generated');
mkdirSync(destination, { recursive: true });
copyFileSync(path.join(root, '_build/js/release/build/src/bindings/web/web.js'), path.join(destination, 'moonspoof.js'));
const notice = '// Unicode data: Copyright © 2024 Unicode, Inc. (Unicode-3.0).\n'
  + '// Keep licenses/UNICODE-3.0.txt and THIRD_PARTY_NOTICES.md with this artifact.\n';
const engineFile = path.join(destination, 'moonspoof.js');
writeFileSync(engineFile, notice + readFileSync(engineFile, 'utf8'));
const command = (name, args) => {
  const result = spawnSync(name, args, { cwd: root, encoding: 'utf8' });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`${name} failed: ${result.stderr}`);
  return result.stdout.trim();
};
const moduleText = readFileSync(path.join(root, 'moon.mod'), 'utf8');
const compilerPin = readFileSync(path.join(root, '.moon-version'), 'utf8').trim();
const compiler = command('moonc', ['-v']);
if (!compiler.includes(`v${compilerPin} `)) throw new Error('Engine compiler differs from .moon-version');
const buildInfo = {
  schema: 1,
  module: /^name\s*=\s*"([^"]+)"/m.exec(moduleText)[1],
  version: /^version\s*=\s*"([^"]+)"/m.exec(moduleText)[1],
  compiler_pin: compilerPin,
  compiler,
  commit: command('git', ['rev-parse', 'HEAD']),
  dirty: command('git', ['status', '--porcelain']).length > 0,
  engine_sha256: createHash('sha256').update(readFileSync(engineFile)).digest('hex'),
};
const metadata = JSON.stringify(buildInfo, null, 2) + '\n';
writeFileSync(path.join(destination, 'build-info.json'), metadata);
mkdirSync(path.join(root, 'playground/public'), { recursive: true });
writeFileSync(path.join(root, 'playground/public/build-info.json'), metadata);
console.log('Browser engine rebuilt from MoonBit source (JavaScript target).');
