import { useEffect, useRef, useState } from 'react';

export function useTask(engine, key) {
  const currentKey = useRef(key);
  currentKey.current = key;
  const sequence = useRef(0);
  const [state, setState] = useState({});
  useEffect(() => () => { sequence.current += 1; }, []);
  async function run(operation, args) {
    const id = ++sequence.current;
    const capturedKey = key;
    setState({ key, busy: true });
    try {
      const result = await engine.request(operation, args);
      if (sequence.current === id && currentKey.current === capturedKey) setState({ key, ...result });
    } catch (error) {
      if (sequence.current === id && currentKey.current === capturedKey) setState({ key, error: error.message });
    }
  }
  return { ...(state.key === key ? state : {}), run };
}
