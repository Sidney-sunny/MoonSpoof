import { useEffect, useMemo, useState } from 'react';
import { EngineClient } from './engine/client.mjs';
import { Compare } from './components/Compare.jsx';
import { Batch, Inspector } from './components/Tools.jsx';
import { COMPARISON } from './data.js';
import { useI18n } from './i18n.jsx';
import { ScrollableTable } from './components/ScrollableTable.jsx';

const tabs = [['compare', 'Pair comparison'], ['batch', 'Collision scanner'], ['inspect', 'Glyph inspector'], ['bidi', 'Bidi audit']];
const github = 'https://github.com/Sidney-sunny/MoonSpoof';
const mooncakes = 'https://mooncakes.io/modules/Sidney-sunny/moonspoof';

export default function App() {
  const { t, language, setLanguage } = useI18n();
  const [tab, setTab] = useState('compare');
  const [status, setStatus] = useState('loading');
  const engine = useMemo(() => new EngineClient(() => new Worker(new URL('./engine/worker.mjs', import.meta.url), { type: 'module' })), []);
  function boot() { setStatus('loading'); engine.ready().then(() => setStatus('ready'), () => setStatus('failed')); }
  useEffect(() => { boot(); return () => engine.dispose(); }, [engine]);
  function moveTab(event, index) {
    let next;
    if (event.key === 'ArrowRight') next = (index + 1) % tabs.length;
    else if (event.key === 'ArrowLeft') next = (index + tabs.length - 1) % tabs.length;
    else if (event.key === 'Home') next = 0;
    else if (event.key === 'End') next = tabs.length - 1;
    if (next !== undefined) { event.preventDefault(); setTab(tabs[next][0]); document.getElementById(`tab-${tabs[next][0]}`).focus(); }
  }
  return <>
    <a className="skip-link" href="#workbench">{t('Skip to workbench')}</a>
    <header className="site-header">
      <a className="wordmark" href="#"><Mark />MoonSpoof<span className="version mono">0.1.0</span></a>
      <nav aria-label={t('Main navigation')}>
        <a href="#workbench">{t('Live demo')}</a>
        <a href="#comparison">{t('Comparison')}</a>
        <a href={mooncakes} target="_blank" rel="noreferrer">Mooncakes<External /></a>
        <a href={`${github}#quickstart`} target="_blank" rel="noreferrer">{t('Source')}<External /></a>
        <button className="language-toggle" type="button" onClick={() => setLanguage(language === 'zh' ? 'en' : 'zh')} aria-label={language === 'zh' ? 'Switch to English' : '切换为中文'}>{language === 'zh' ? 'EN' : '中文'}</button>
      </nav>
    </header>
    <main>
      <section className="intro wrap">
        <div><h1>{t('Looks the same.')}<br /><span>{t('Is it?')}</span></h1><p>{t('Unicode spoof detection, built in MoonBit.')}<br />{t('Turn a convincing lookalike into inspectable evidence.')}</p></div>
        <div className="intro-aside"><span className="intro-symbol" aria-hidden="true">а<span>a</span></span><p>{t('Different codepoints.')}<br />{t('One visual identity.')}</p><a href="#workbench" className="text-link">{t('Examine the difference')}<External /></a></div>
      </section>
      <section className="workbench wrap" id="workbench">
        <div className="workbench-nav"><div role="tablist" aria-label={t('Engine tools')}>{tabs.map(([value, label], index) => <button role="tab" id={`tab-${value}`} key={value} aria-selected={tab === value} aria-controls={`panel-${value}`} tabIndex={tab === value ? 0 : -1} onClick={() => setTab(value)} onKeyDown={event => moveTab(event, index)}>{t(label)}</button>)}</div><span className="engine-status mono" role="status">{status === 'ready' ? t('JS engine / local') : status === 'loading' ? t('Starting engine…') : t('Engine unavailable')}</span></div>
        {status === 'failed' && <p className="error-text" role="alert">{t('The engine failed to start.')} <button className="text-button" onClick={boot}>{t('Retry engine')}</button></p>}
        {tabs.map(([value]) => <div key={value} id={`panel-${value}`} role="tabpanel" aria-labelledby={`tab-${value}`} tabIndex={0} hidden={tab !== value}>
          {value === 'compare' && <Compare engine={engine} ready={status === 'ready'} />}
          {value === 'batch' && <Batch engine={engine} ready={status === 'ready'} />}
          {value === 'inspect' && <Inspector engine={engine} ready={status === 'ready'} />}
          {value === 'bidi' && <Inspector engine={engine} ready={status === 'ready'} bidi />}
        </div>)}
        <div className="workbench-footer"><span>{t('Input stays on this device. No API request.')}</span><span>{t('MoonBit source → JavaScript → Web Worker')}</span></div>
      </section>
      <section className="comparison-section wrap" id="comparison">
        <div className="section-heading"><h2>{t('A different integration.')}<br /><span>{t('An honest comparison.')}</span></h2><p>{t('MoonSpoof brings Unicode security primitives to MoonBit. ICU remains the broader standards implementation; the difference here is integration and inspectability.')}</p></div>
        <ScrollableTable label="Competitor comparison table"><table className="comparison-table"><caption className="sr-only">{t('Documented capabilities, not a measured speed ranking')}</caption><thead><tr><th scope="col">{t('Capability')}</th><th scope="col" className="moon-column">MoonSpoof</th><th scope="col">ICU SpoofChecker</th><th scope="col">confusable_homoglyphs</th></tr></thead><tbody>{COMPARISON.map(([label, moon, icu, python]) => <tr key={label}><th scope="row">{t(label)}</th><td className="moon-column">{t(moon)}</td><td>{t(icu)}</td><td>{t(python)}</td></tr>)}</tbody></table></ScrollableTable>
        <div className="comparison-sources"><span>{t('API references · reviewed 11 Oct 2026')}</span><a href="https://unicode-org.github.io/icu-docs/apidoc/released/icu4c/uspoof_8h.html" target="_blank" rel="noreferrer">ICU<External /></a><a href="https://confusable-homoglyphs.readthedocs.io/en/latest/apidocumentation.html" target="_blank" rel="noreferrer">confusable_homoglyphs<External /></a><a href="https://www.unicode.org/reports/tr39/tr39-30.html" target="_blank" rel="noreferrer">UTS #39<External /></a></div>
      </section>
      <section className="implementation wrap" id="implementation">
        <div>
          <h2>{t('Small surface.')}<br />{t('Inspectable core.')}</h2>
          <p>{t('Generated, version-pinned Unicode data. Pure MoonBit algorithms. The same facade serves the browser, command line, and library integrations.')}</p>
          <div style={{ marginBlock: '16px', display: 'flex', gap: '10px', alignItems: 'center', flexWrap: 'wrap' }}>
            <span className="mono" style={{ padding: '6px 12px', background: 'var(--surface)', border: '1px solid var(--line)', borderRadius: '4px', fontSize: '13px' }}>moon add Sidney-sunny/moonspoof</span>
            <a className="text-link" href={mooncakes} target="_blank" rel="noreferrer" style={{ fontSize: '13px' }}>Mooncakes<External /></a>
          </div>
          <a className="text-link" href={`${github}/blob/main/docs/ARCHITECTURE.md`} target="_blank" rel="noreferrer">{t('Explore the architecture')}<External /></a>
        </div>
        <div className="code-sample"><div className="section-line"><span>{t('MoonBit / pair comparison')}</span><span className="mono">moonspoof.mbt</span></div><pre><code><span className="code-keyword">let</span> reference = <span className="code-string">"paypal"</span>{'\n'}<span className="code-keyword">let</span> candidate = <span className="code-string">{'"p\\u0430ypal"'}</span>{'\n\n'}@moonspoof.are_confusable(reference, candidate){'\n'}<span className="code-comment">// true — both keys are "paypal"</span>{'\n\n'}@moonspoof.analyze_identifier(candidate){'\n'}<span className="code-comment">// codepoints, scripts, prototypes, risk signals</span></code></pre></div>
      </section>
      <section className="limits-section wrap"><h2>{t('Know the boundary.')}</h2><p>{t('This is a scoped UTS #39 implementation, not a phishing verdict. NFD, full case folding, confusable mappings, and default ignorables use Unicode 16.0 data. Script analysis currently exposes eleven script categories; other scripts are reported as Unknown. Full Script_Extensions resolution, Identifier_Status validation, mixed-number detection, and bidi skeleton reordering are not implemented. Fullwidth ASCII folding and repeated normalization to a stable key are application extensions.')}</p><a className="text-link" href={`${github}/blob/main/docs/SPECIFICATION.md`} target="_blank" rel="noreferrer">{t('Read the implementation scope')}<External /></a></section>
    </main>
    <footer className="site-footer wrap">
      <a className="wordmark" href="#"><Mark />MoonSpoof</a>
      <span>{t('MoonBit Hackathon 2026 · Apache-2.0')}</span>
      <div style={{ display: 'flex', gap: '20px', alignItems: 'center', flexWrap: 'wrap' }}>
        <a href={mooncakes} target="_blank" rel="noreferrer">mooncakes: Sidney-sunny/moonspoof<External /></a>
        <a href={github} target="_blank" rel="noreferrer">GitHub: Sidney-sunny/MoonSpoof<External /></a>
      </div>
    </footer>
  </>;
}

function External() { return <svg aria-hidden="true" width="14" height="14" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.4"><path d="M5 15 15 5M5 5h10v10" /></svg>; }
function Mark() { return <img className="brand-mark" src={`${import.meta.env.BASE_URL}logo.png`} width="48" height="48" alt="" />; }
