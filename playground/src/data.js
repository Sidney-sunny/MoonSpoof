export const CASES = {
  homoglyph: { label: 'Cyrillic substitution', a: 'paypal', b: 'p\u0430ypal', note: 'A Latin a and a Cyrillic а. Same shape, different identity.' },
  invisible: { label: 'Invisible character', a: 'admin', b: 'admin\u200B', note: 'A zero-width space leaves no visible trace. Inspect the codepoints.' },
  bidi: { label: 'Bidi filename', a: 'invoiceexe.pdf', b: 'invoice\u202Eexe.pdf', note: 'A right-to-left override changes display order. The control is flagged.' },
  canonical: { label: 'Canonical equivalence', a: 'café', b: 'cafe\u0301', note: 'One accented character or a base plus combining mark. Both normalize equally.' },
  multilingual: { label: 'Multilingual identifier', a: 'Moon月あア', b: 'Moon月あア', note: 'A legitimate Japanese script combination. Mixed scripts alone do not prove an attack.' },
  distinct: { label: 'Distinct identifiers', a: 'alice', b: 'bob', note: 'Different skeletons. Confusable analysis does not measure reputation.' },
};

export const BATCH_SAMPLE = ['paypal', 'p\u0430ypal', 'PAYPAL', 'admin', 'adm\u0456n', 'admin\u200B', 'alice', 'ALICE', 'bob', 'Moon月あア'].join('\n');
export const RISK_LABELS = { Safe: 'No elevated risk signal', Low: 'Mapped glyph', Medium: 'Review advised', High: 'Cross-script signal', Critical: 'Control character signal' };

export function isControlCodepoint(cp) { return cp < 32 || (cp >= 0x7f && cp <= 0x9f); }

export const COMPARISON = [
  ['Primary runtime', 'MoonBit · JS / WASM / native', 'C / C++ · Java', 'Python'],
  ['Pair matching', 'Canonical skeleton keys', 'SpoofChecker + skeleton API', 'Glyphs against preferred scripts'],
  ['Character evidence', 'Codepoint, script, target, rules', 'Check flags and restriction results', 'Confusable glyph candidates'],
  ['Batch grouping', 'Built-in skeleton buckets', 'Compose with skeleton API', 'Application-defined grouping'],
  ['Standards coverage', 'Scoped implementation; gaps below', 'Broader Unicode security implementation', 'Mixed-script and homoglyph checks'],
];
