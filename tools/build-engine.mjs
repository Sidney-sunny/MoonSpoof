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
const command = (name, args, optional = false) => {
  const result = spawnSync(name, args, { cwd: root, encoding: 'utf8' });
  if (optional && (result.error || result.status !== 0)) return null;
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`${name} failed: ${result.stderr}`);
  return result.stdout.trim();
};
const moduleText = readFileSync(path.join(root, 'moon.mod'), 'utf8');
const compilerPin = readFileSync(path.join(root, '.moon-version'), 'utf8').trim();
const compiler = command('moonc', ['-v']);
if (!compiler.includes(`v${compilerPin} `)) throw new Error('Engine compiler differs from .moon-version');
const moduleName = /^name\s*=\s*"([^"]+)"/m.exec(moduleText)[1];
const moduleVersion = /^version\s*=\s*"([^"]+)"/m.exec(moduleText)[1];
const gitRoot = command('git', ['rev-parse', '--show-toplevel'], true);
let commit;
let dirty;
if (gitRoot && path.resolve(gitRoot) === path.resolve(root)) {
  commit = command('git', ['rev-parse', 'HEAD']);
  dirty = command('git', ['status', '--porcelain']).length > 0;
} else {
  // Release source ZIPs have no .git. They can be built for use, but their
  // modified/unversioned trees must not qualify as clean release inputs.
  const sourceInfo = JSON.parse(readFileSync(path.join(root, 'build-info.json'), 'utf8'));
  if (sourceInfo.schema !== 1 || sourceInfo.module !== moduleName
      || sourceInfo.version !== moduleVersion || sourceInfo.compiler_pin !== compilerPin
      || !/^[a-f0-9]{40,64}$/.test(sourceInfo.commit)) {
    throw new Error('Source archive metadata does not match this project');
  }
  commit = sourceInfo.commit;
  dirty = true;
}
const buildInfo = {
  schema: 1,
  module: moduleName,
  version: moduleVersion,
  compiler_pin: compilerPin,
  compiler,
  commit,
  dirty,
  engine_sha256: createHash('sha256').update(readFileSync(engineFile)).digest('hex'),
};
const metadata = JSON.stringify(buildInfo, null, 2) + '\n';
writeFileSync(path.join(destination, 'build-info.json'), metadata);
mkdirSync(path.join(root, 'playground/public'), { recursive: true });
writeFileSync(path.join(root, 'playground/public/build-info.json'), metadata);
console.log('Browser engine rebuilt from MoonBit source (JavaScript target).');
