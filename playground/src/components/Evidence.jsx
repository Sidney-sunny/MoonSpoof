import { useI18n } from '../i18n.jsx';
import { ScrollableTable } from './ScrollableTable.jsx';
import { isControlCodepoint } from '../data.js';

export function Evidence({ report, selected, onSelect }) {
  const { t } = useI18n();
  if (!report) return null;
  return <div className="evidence">
    <div className="section-line"><h3>{t('Character evidence')}</h3><span className="mono">{t('{count} codepoints', { count: report.chars.length })}</span></div>
    <ScrollableTable label="Character evidence table"><table className="evidence-table">
      <caption className="sr-only">{t('Character mappings and security signals')}</caption>
      <thead><tr><th scope="col">{t('Position')}</th><th scope="col">{t('Glyph')}</th><th scope="col">{t('Codepoint')}</th><th scope="col">{t('Script')}</th><th scope="col">{t('Prototype / signal')}</th></tr></thead>
      <tbody>{report.chars.map((char, index) => <tr key={index} className={selected === index ? 'selected-row' : ''}>
        <td className="mono">{String(index + 1).padStart(2, '0')}</td>
        <td><button className="glyph-select" onClick={() => onSelect(index)} aria-pressed={selected === index} aria-label={t('Inspect position {position}, {hex}', { position: index + 1, hex: char.hex })}>{char.is_invisible || char.is_bidi || isControlCodepoint(char.codepoint) ? '∅' : <bdi>{char.char}</bdi>}</button></td>
        <td className="mono">{char.hex}</td><td>{t(char.script)}</td>
        <td className={char.is_invisible || char.is_bidi || char.is_confusable ? 'signal-text' : 'muted'}>
          {char.is_bidi ? t('Bidi control') : char.is_invisible ? t('Default ignorable') : isControlCodepoint(char.codepoint) ? t('Control') : char.is_confusable ? <><bdi className="mono">{char.confusable_target}</bdi> · {t('mapped')}</> : t('Unchanged')}
        </td>
      </tr>)}</tbody>
    </table></ScrollableTable>
  </div>;
}

export function Rules({ report }) {
  const { t } = useI18n();
  if (!report) return null;
  return <div className="rule-list">{report.rules_triggered.map(rule => <div key={rule} className="mono">{t(rule.replace('RULE_', '').toLowerCase().replaceAll('_', ' '))}</div>)}</div>;
}

export function TaskState({ task }) {
  const { t } = useI18n();
  return <>{task.error && <p className="error-text" role="alert">{t(task.error)}</p>}{task.milliseconds !== undefined && <span className="timing mono">{t('{time} ms · worker execution on this device', { time: task.milliseconds.toFixed(2) })}</span>}</>;
}
