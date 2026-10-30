import { createHash } from 'node:crypto';

// Exact UTF-8 spelling and order are part of the benchmark fixture contract.
export const keyCorpus = [
  'alice', 'PAYPAL', 'paypal', 'p\u0430ypal', 'a\u03B1', 'admin\u200B', 'user_name_123', 'Stra\u00DFe',
  'STRASSE', '\u00E9quipe', 'e\u0301quipe', '\u212Bngstrom', '\u00C5ngstrom', '\u03A3\u03AF\u03B3\u03BC\u03B1', '\u03C3\u03C2', '\u041C\u043E\u0441\u043A\u0432\u0430',
  '\u4E2D\u6587', '\u65E5\u672C\u8A9E\u30E6\u30FC\u30B6\u30FC', '\uD55C\uAE00', '\u0928\u092E\u0938\u094D\u0924\u0947', '\u0E20\u0E32\u0E29\u0E32\u0E44\u0E17\u0E22', '\u05E9\u05DC\u05D5\u05DD', '\u0645\u0631\u062D\u0628\u0627', '\u{1E900}\u{1E922}',
  '\u{1D400}dmin', '\uFF21\uFF22\uFF23\uFF11\uFF12\uFF13', 'user1\u0661', '\u{20000}\u4E2D', 'a\u0301\u0323', 'a\u0323\u0301', '\uFB03le', 'a' + '\u0301\u0323'.repeat(8),
];

export function batchCorpus(count) {
  if (!Number.isInteger(count) || count <= 0 || count % 10 !== 0) {
    throw new Error('Batch size must be a positive multiple of ten');
  }
  const names = Array.from({ length: count }, (_, index) => {
    const cluster = Math.floor(index / 10);
    return [
      `paypal_${cluster}`, `p\u0430ypal_${cluster}`, `PAYPAL_${cluster}`, `PayPal_${cluster}`,
      `admin_${cluster}`, `admin\u200B_${cluster}`, `ADMIN_${cluster}`, `user_${index}`,
      `Team_${cluster}`, `team_${cluster}`,
    ][index % 10];
  });
  return { names, raw: names.join('\n') };
}

export function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

export function summarizeCorpus(names, raw = names.join('\n')) {
  const lengths = names.map(name => [...name].length);
  return {
    identifiers: names.length,
    utf8Bytes: Buffer.byteLength(raw, 'utf8'),
    utf16Units: names.reduce((sum, name) => sum + name.length, 0),
    codepoints: lengths.reduce((sum, length) => sum + length, 0),
    codepointsPerIdentifier: { minimum: Math.min(...lengths), maximum: Math.max(...lengths) },
    serialization: 'UTF-8 names joined by LF with no trailing LF',
    sha256: sha256(raw),
  };
}
