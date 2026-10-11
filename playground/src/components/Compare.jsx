import { useEffect, useState } from 'react';
import { CASES, RISK_LABELS, isControlCodepoint } from '../data.js';
import { useTask } from '../engine/useTask.js';
import { Evidence, Rules, TaskState } from './Evidence.jsx';
import { useI18n } from '../i18n.jsx';

export function Compare({ engine, ready }) {
  const { t } = useI18n();
  const [scenario, setScenario] = useState('homoglyph');
  const [a, setA] = useState(CASES.homoglyph.a);
  const [b, setB] = useState(CASES.homoglyph.b);
  const [ignoreCase, setIgnoreCase] = useState(false);
  const [selected, setSelected] = useState(1);
  const key = JSON.stringify([a, b, ignoreCase]);
  const task = useTask(engine, key);
  function run() { task.run('compare', { a, b }); }
  useEffect(() => { if (ready) run(); }, [ready]);
  function choose(value) {
    const item = CASES[value];
    setScenario(value); setA(item.a); setB(item.b); setSelected(value === 'invisible' ? 5 : 1);
  }
  const result = task.data;
  const match = result && (ignoreCase ? result.are_confusable_ignore_case : result.are_confusable);
  const identical = result && a === b;
  const active = result?.b.chars[selected];
  const maxGlyphs = 20;

  return <>
    <div className="comparison-stage">
      <div className="specimen">
        <div className="specimen-meta"><span>{t('Reference / candidate')}</span><span className="mono">Unicode 16.0</span></div>
        <div className="specimen-word" dir="ltr" aria-label={t('Reference: {text}', { text: a })}><bdi>{[...a].slice(0, maxGlyphs).join('') || '∅'}</bdi>{[...a].length > maxGlyphs && <span className="truncated">…</span>}</div>
        <div className="specimen-word candidate" dir="ltr" aria-label={t('Candidate: {text}', { text: b })}>
          {result ? result.b.chars.slice(0, maxGlyphs).map((char, index) => <button key={index} className={`${selected === index ? 'selected-glyph' : ''} ${char.is_confusable || char.is_bidi || char.is_invisible || isControlCodepoint(char.codepoint) ? 'mapped-glyph' : ''}`} aria-label={t('Inspect {hex} at position {position}', { hex: char.hex, position: index + 1 })} aria-pressed={selected === index} onClick={() => setSelected(index)}>{char.is_invisible || char.is_bidi || isControlCodepoint(char.codepoint) ? <span className="invisible-glyph">∅</span> : char.char}</button>) : <bdi>{[...b].slice(0, maxGlyphs).join('') || '∅'}</bdi>}
          {[...b].length > maxGlyphs && <span className="truncated">…</span>}
        </div>
        <div className="specimen-foot"><span>{scenario ? t(CASES[scenario].note) : t('Custom input. Run the comparison to inspect character evidence.')}</span></div>
        <div className="codepoint-focus" aria-live="polite">
          {active ? <><strong className="focus-character"><bdi>{active.is_invisible || active.is_bidi || isControlCodepoint(active.codepoint) ? '∅' : active.char}</bdi></strong><div><span className="mono">{active.hex}</span><p>{t(active.script)}{active.is_bidi ? ` · ${t('bidi control')}` : active.is_invisible ? ` · ${t('invisible')}` : isControlCodepoint(active.codepoint) ? ` · ${t('Control')}` : ''}</p></div><div className="focus-mapping"><span className="muted">{t('Prototype')}</span><strong className="mono"><bdi>{active.confusable_target || t('removed')}</bdi></strong></div></> : <span className="muted">{t('Run comparison to reveal codepoints.')}</span>}
        </div>
      </div>
      <form className="comparison-controls" onSubmit={event => { event.preventDefault(); run(); }}>
        <div className="section-line"><h2>{t('Try the engine')}</h2><span className="mono">{t('Local execution')}</span></div>
        <label htmlFor="scenario">{t('Test case')}</label>
        <select id="scenario" value={scenario} onChange={event => choose(event.target.value)}><option value="" disabled>{t('Custom input')}</option>{Object.entries(CASES).map(([value, item]) => <option value={value} key={value}>{t(item.label)}</option>)}</select>
        <label htmlFor="reference">{t('Reference identifier')}</label><input id="reference" value={a} onChange={event => { setA(event.target.value); setScenario(''); }} maxLength={1024} spellCheck="false" autoComplete="off" dir="ltr" />
        <label htmlFor="candidate">{t('Candidate identifier')}</label><input id="candidate" value={b} onChange={event => { setB(event.target.value); setScenario(''); }} maxLength={1024} spellCheck="false" autoComplete="off" dir="ltr" />
        <label className="checkbox"><input type="checkbox" checked={ignoreCase} onChange={event => setIgnoreCase(event.target.checked)} />{t('Ignore case using a folded skeleton key')}</label>
        <button className="primary-button" disabled={!ready || task.busy}>{task.busy ? t('Comparing…') : t('Compare identifiers')}<span aria-hidden="true"><Arrow /></span></button>
        <div className={`verdict ${result && match && !identical ? 'finding' : ''}`} role="status">
          <span className="verdict-mark" aria-hidden="true">{result ? match ? '=' : '≠' : '—'}</span><div><h3>{!result ? task.busy ? t('Analyzing input') : t('Ready to compare') : identical ? t('Identical identifiers') : match ? t('Same skeleton. Different text.') : t('Distinct skeletons')}</h3><p>{result ? identical ? t('Equality alone is not a spoof signal.') : match ? t('These identifiers collide under the selected policy.') : t('No skeleton collision for this pair.') : t('Edit either identifier and run comparison.')}</p></div>
        </div>
        {result && <div className="result-details"><div><span>{t('Reference key')}</span><bdi className="mono">{ignoreCase ? result.a.skeleton_case_folded : result.a.skeleton}</bdi></div><div><span>{t('Candidate key')}</span><bdi className="mono">{ignoreCase ? result.b.skeleton_case_folded : result.b.skeleton}</bdi></div><div><span>{t('Candidate risk')}</span><span className="signal-text">{t(result.b.risk_level)} · {t(RISK_LABELS[result.b.risk_level])}</span></div></div>}
        <TaskState task={task} />
      </form>
    </div>
    {result && <><Evidence report={result.b} selected={selected} onSelect={setSelected} /><Rules report={result.b} /></>}
  </>;
}

function Arrow() { return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M4 12h15M13 6l6 6-6 6" /></svg>; }
