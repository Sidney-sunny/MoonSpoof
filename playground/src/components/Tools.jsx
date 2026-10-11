import { useState } from 'react';
import { BATCH_SAMPLE } from '../data.js';
import { useTask } from '../engine/useTask.js';
import { Evidence, Rules, TaskState } from './Evidence.jsx';
import { useI18n } from '../i18n.jsx';

export function Batch({ engine, ready }) {
  const { t } = useI18n();
  const [input, setInput] = useState(BATCH_SAMPLE);
  const [ignoreCase, setIgnoreCase] = useState(true);
  const task = useTask(engine, JSON.stringify([input, ignoreCase]));
  return <div className="tool-layout">
    <form onSubmit={event => { event.preventDefault(); task.run('batch', { input, ignoreCase }); }}>
      <h2>{t('One list. Every collision.')}</h2><p className="muted">{t('Skeleton buckets group colliding identifiers without comparing every pair.')}</p>
      <label htmlFor="batch-input">{t('Identifiers · one per line or comma separated')}</label><textarea id="batch-input" value={input} onChange={event => setInput(event.target.value)} rows={12} maxLength={200000} spellCheck="false" dir="ltr" />
      <label className="checkbox"><input type="checkbox" checked={ignoreCase} onChange={event => setIgnoreCase(event.target.checked)} />{t('Ignore case')}</label>
      <button className="primary-button" disabled={!ready || task.busy}>{task.busy ? t('Scanning…') : t('Scan for collisions')}</button><TaskState task={task} />
    </form>
    <div className="scan-results" aria-live="polite">{task.data && <><div className="section-line"><h3>{t('{count} collision groups', { count: task.data.group_count })}</h3><span className="mono">{t('{count} identifiers', { count: task.data.total_names })}</span></div>
      {task.data.groups.map((group, index) => <div className="collision-group" key={index}><div className="section-line"><bdi className="mono signal-text">{group.skeleton}</bdi><span>{t('{count} entries', { count: group.count })}</span></div><ul>{group.members.map((member, i) => <li key={i}><bdi className="mono">{escapeControls(member)}</bdi></li>)}</ul></div>)}
      {!task.data.group_count && <p>{t('No collisions in this list.')}</p>}<p className="muted">{t('Repeated identical entries also count as collisions.')}</p></>}</div>
  </div>;
}

export function Inspector({ engine, ready, bidi = false }) {
  const { t } = useI18n();
  const [input, setInput] = useState(bidi ? 'invoice\u202Eexe.pdf' : 'p\u0430ypal');
  const [permissive, setPermissive] = useState(false);
  const [selected, setSelected] = useState(0);
  const inputId = bidi ? 'bidi-input' : 'inspect-input';
  const task = useTask(engine, JSON.stringify([input, permissive]));
  return <>
    <div className="tool-layout">
      <form onSubmit={event => { event.preventDefault(); task.run('inspect', { input, permissive }); }}>
        <h2>{bidi ? t('Expose hidden direction.') : t('Inspect an identifier.')}</h2><p className="muted">{bidi ? t('Browser display follows bidi rules. Escaped source exposes the stored control characters.') : t('Inspect the script, mapping, and policy result for every codepoint.')}</p>
        <label htmlFor={inputId}>{bidi ? t('Source text or filename') : t('Identifier')}</label><textarea id={inputId} value={input} onChange={event => setInput(event.target.value)} rows={4} maxLength={1024} spellCheck="false" dir="ltr" />
        <label className="checkbox"><input type="checkbox" checked={permissive} onChange={event => setPermissive(event.target.checked)} />{t('Allow mixed scripts in identifier policy')}</label>
        <button className="primary-button" disabled={!ready || task.busy}>{task.busy ? t('Inspecting…') : t('Inspect codepoints')}</button><TaskState task={task} />
      </form>
      <div>{task.data && <><div className="section-line"><h3>{t('{level} risk signal', { level: t(task.data.risk_level) })}</h3><span>{t(task.data.primary_script)}</span></div>
        {bidi && <div className="bidi-views"><span className="muted">{t('Browser visual rendering')}</span><div className="rendered-source"><bdi dir="auto">{task.data.original}</bdi></div><span className="muted">{t('Stored source · controls escaped')}</span><code>{escapeControls(task.data.original)}</code></div>}
        <div className="result-details"><div><span>{t('Skeleton')}</span><bdi className="mono">{task.data.skeleton}</bdi></div><div><span>{t('Restriction estimate')}</span><span>{t(task.data.restriction_level)}</span></div><div><span>{t('Identifier policy')}</span><span>{task.data.profile.valid ? t('Accepted') : t('Rejected')}</span></div></div>
        {!task.data.profile.valid && <p className="signal-text">{t(task.data.profile.error)}</p>}<Rules report={task.data} />
      </>}</div>
    </div>
    {task.data && <Evidence report={task.data} selected={selected} onSelect={setSelected} />}
  </>;
}

export function escapeControls(text) {
  return [...text].map(char => {
    const cp = char.codePointAt(0);
    return cp < 32 || (cp >= 0x7f && cp <= 0x9f) || /[\p{Default_Ignorable_Code_Point}]/u.test(char) ? `\\u{${cp.toString(16).toUpperCase()}}` : char;
  }).join('');
}
