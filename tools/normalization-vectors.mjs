// Parse the five official NormalizationTest columns without a derived cache.
export function parseNormalizationVectors(text) {
  const vectors = [];
  for (const [index, line] of text.split('\n').entries()) {
    const row = line.split('#')[0].trim();
    if (!row || row.startsWith('@')) continue;
    const invalid = () => new Error(`Invalid NormalizationTest row at line ${index + 1}.`);
    const fields = row.split(';');
    if (fields.length !== 6 || fields.pop().trim() !== '') throw invalid();
    vectors.push(fields.map(field => field.trim().split(/\s+/).map(hex => {
      if (!/^[0-9a-f]{4,6}$/i.test(hex)) throw invalid();
      const codepoint = Number.parseInt(hex, 16);
      if (codepoint > 0x10FFFF || (codepoint >= 0xD800 && codepoint <= 0xDFFF)) throw invalid();
      return String.fromCodePoint(codepoint);
    }).join('')));
  }
  if (vectors.length === 0) throw new Error('NormalizationTest contains no test vectors.');
  return vectors;
}
