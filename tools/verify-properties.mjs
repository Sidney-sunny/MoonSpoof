import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import path from 'node:path';

// Independent reference: expand verified official files across the code space.
// No generated MoonBit table or derived cache supplies expected values.
export function verifyUnicodeProperties(engine, directory) {
  const read = name => readFileSync(path.join(directory, name), 'utf8');
  const rows = text => text.split(/\r?\n/).map(line => line.split('#')[0].trim())
    .filter(Boolean).map(line => line.split(';').map(field => field.trim()));
  const bounds = field => {
    const ends = field.split('..').map(value => Number.parseInt(value, 16));
    return [ends[0], ends.at(-1) + 1];
  };
  const aliases = new Map();
  for (const [property, short, long, ...others] of rows(read('PropertyValueAliases.txt'))) {
    if (property === 'sc') for (const alias of [short, long, ...others]) aliases.set(alias, long);
  }
  const size = 0x110000;
  const scripts = new Array(size).fill('Unknown');
  const extensions = new Array(size).fill(null);
  const allowed = new Uint8Array(size);
  for (const [range, script] of rows(read('Scripts.txt'))) scripts.fill(script, ...bounds(range));
  for (const [range, set] of rows(read('ScriptExtensions.txt'))) {
    const names = set.split(/\s+/).map(alias => {
      assert(aliases.has(alias), `Unresolved official script alias: ${alias}`);
      return aliases.get(alias);
    }).sort();
    extensions.fill(JSON.stringify(names), ...bounds(range));
  }
  for (const [range, status] of rows(read('IdentifierStatus.txt'))) {
    assert.equal(status, 'Allowed');
    allowed.fill(1, ...bounds(range));
  }
  for (let cp = 0; cp < size; cp++) {
    assert.equal(engine.spoof_unicode_script(cp), scripts[cp], `Script U+${cp.toString(16)}`);
    assert.equal(engine.spoof_script_extensions(cp), extensions[cp] ?? `["${scripts[cp]}"]`, `Script_Extensions U+${cp.toString(16)}`);
    assert.equal(Boolean(engine.spoof_identifier_status_allowed(cp)), Boolean(allowed[cp]), `Identifier_Status U+${cp.toString(16)}`);
  }
  return { propertyCodepoints: size, propertyAssertions: size * 3 };
}
