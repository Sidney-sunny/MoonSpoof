import { test } from 'node:test';
import assert from 'node:assert/strict';
import { parseNormalizationVectors } from '../../tools/normalization-vectors.mjs';

test('official columns preserve composition, combining marks, and Hangul', () => {
  const text = '# Unicode normalization fixtures\r\n@Part0 # Specific cases\r\n'
    + '1E0A;1E0A;0044 0307;1E0A;0044 0307; # D with dot\r\n'
    + '\r\n@Part1\r\nAC00;AC00;1100 1161;AC00;1100 1161;\r\n';
  assert.deepEqual(parseNormalizationVectors(text), [
    ['Ḋ', 'Ḋ', 'D\u0307', 'Ḋ', 'D\u0307'],
    ['가', '가', '\u1100\u1161', '가', '\u1100\u1161'],
  ]);
});

test('supplementary codepoints survive all five columns', () => {
  assert.deepEqual(parseNormalizationVectors('1D400;1D400;1D400;0041;0041;'), [
    ['\u{1D400}', '\u{1D400}', '\u{1D400}', 'A', 'A'],
  ]);
});

test('empty and comment-only input cannot silently skip all normalization checks', () => {
  for (const text of ['', '# header\n\n@Part0 # no rows\n']) {
    assert.throws(() => parseNormalizationVectors(text), /no test vectors/);
  }
});

test('truncated columns and invalid scalar values report the source line', () => {
  const invalidRows = [
    '0041;0041;0041;',
    '0041;0041;;0041;0041;',
    '0041;0041;0041;0041;0041;unexpected',
    ...['0041x', '110000', 'D800'].map(cp => Array(5).fill(cp).join(';') + ';'),
  ];
  for (const row of invalidRows) {
    assert.throws(() => parseNormalizationVectors('# header\n' + row), /row at line 2/);
  }
});
