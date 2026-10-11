import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execute } from '../src/engine/operations.mjs';

test('pair matching and batch grouping agree under both policies', () => {
  for (const [a, b] of [['I', 'l'], ['ALICE', 'alice'], ['Straße', 'STRASSE'], ['paypal', 'pаypal'], ['é', 'e\u0301']]) {
    const pair = execute('compare', { a, b });
    assert.equal(execute('batch', { input: `${a}\n${b}` }).group_count > 0, pair.are_confusable);
    assert.equal(execute('batch', { input: `${a}\n${b}`, ignoreCase: true }).group_count > 0, pair.are_confusable_ignore_case);
  }
});

test('all controls survive JSON ABI round trips including quotes and supplementary characters', () => {
  for (let cp = 0; cp < 32; cp++) {
    const input = `x${String.fromCodePoint(cp)}"\\𠀀`;
    const result = execute('inspect', { input });
    assert.equal(result.original, input);
    assert.equal(result.chars.map(char => char.char).join(''), input);
  }
});

test('input limits reject oversized scans and count individual codepoints', () => {
  assert.throws(() => execute('inspect', { input: 'a'.repeat(513) }), /512/);
  assert.throws(() => execute('batch', { input: Array(5001).fill('a').join('\n') }), /5,000/);
  assert.throws(() => execute('batch', { input: 'a'.repeat(200001) }), /200,000/);
  assert.equal(execute('inspect', { input: '𠀀'.repeat(512) }).chars.length, 512);
  assert.throws(() => execute('inspect', { input: null }), /text/);
  assert.throws(() => execute('invalid', {}), /Unknown/);
});

test('empty scans, CRLF, commas, and duplicate entries have stable results', () => {
  assert.equal(execute('batch', { input: ' \n,\r\n ' }).group_count, 0);
  const report = execute('batch', { input: 'paypal\r\nadmin, pаypal,admin' });
  assert.equal(report.total_names, 4);
  assert.deepEqual(report.groups.map(group => group.members), [['paypal', 'pаypal'], ['admin', 'admin']]);
});

test('bidi and multilingual reports expose signals without treating equality as evidence of an attack', () => {
  const bidi = execute('inspect', { input: 'invoice\u202Eexe.pdf' });
  assert.equal(bidi.risk_level, 'Critical');
  assert.ok(bidi.rules_triggered.includes('RULE_BIDI_OVERRIDE_CHARACTER'));
  const japanese = execute('inspect', { input: 'a中あア', permissive: true });
  assert.equal(japanese.restriction_level, 'HighlyRestrictive');
  assert.equal(japanese.profile.valid, true);
  assert.notEqual(japanese.risk_level, 'High');
});
