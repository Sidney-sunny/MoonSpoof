import { spawnSync } from 'node:child_process';
import { copyFileSync, mkdirSync } from 'node:fs';
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
console.log('Browser engine rebuilt from MoonBit source (JavaScript target).');
