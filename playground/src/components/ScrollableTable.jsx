import { useEffect, useRef, useState } from 'react';
import { useI18n } from '../i18n.jsx';

export function ScrollableTable({ label, children }) {
  const { t } = useI18n();
  const region = useRef(null);
  const [overflow, setOverflow] = useState(false);
  useEffect(() => {
    const element = region.current;
    const observer = new ResizeObserver(() => setOverflow(element.scrollWidth > element.clientWidth + 1));
    observer.observe(element);
    observer.observe(element.firstElementChild);
    return () => observer.disconnect();
  }, []);
  return <>
    {overflow && <p className="scroll-cue">{t('Scroll sideways to see all columns. Keyboard: Left / Right.')}</p>}
    <div ref={region} className="table-scroll" role="region" aria-label={t(label)} tabIndex={overflow ? 0 : undefined}>{children}</div>
  </>;
}
