import * as abi from '../generated/moonspoof.js';

export const LIMITS = Object.freeze({ identifier: 512, batchCharacters: 200_000, batchNames: 5_000 });

function identifier(text) {
  if (typeof text !== 'string') throw new TypeError('An identifier must be text.');
  if ([...text].length > LIMITS.identifier) throw new RangeError(`Use at most ${LIMITS.identifier} codepoints per identifier.`);
  return text;
}

export function execute(operation, args) {
  if (!args || typeof args !== 'object') throw new TypeError('Missing operation arguments.');
  switch (operation) {
    case 'compare': {
      const a = identifier(args.a), b = identifier(args.b);
      const comparison = JSON.parse(abi.spoof_compare(a, b));
      return { ...comparison, b: JSON.parse(abi.spoof_analyze(b)) };
    }
    case 'inspect': {
      const input = identifier(args.input);
      return {
        ...JSON.parse(abi.spoof_analyze(input)),
        profile: JSON.parse(abi.spoof_validate_profile(input, args.permissive === true)),
      };
    }
    case 'batch': {
      if (typeof args.input !== 'string') throw new TypeError('The identifier list must be text.');
      if (args.input.length > LIMITS.batchCharacters) throw new RangeError('Use at most 200,000 characters per scan.');
      const names = args.input.split(/[\n\r,]/).map(text => text.trim()).filter(Boolean);
      if (names.length > LIMITS.batchNames) throw new RangeError('Use at most 5,000 identifiers per scan.');
      names.forEach(identifier);
      return JSON.parse(abi.spoof_batch_scan_with_options(args.input, args.ignoreCase === true));
    }
    default: throw new Error('Unknown engine operation.');
  }
}
