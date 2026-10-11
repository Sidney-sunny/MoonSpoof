import { execute } from './operations.mjs';

self.onmessage = ({ data }) => {
  const { id, operation, args } = data;
  const start = performance.now();
  try {
    self.postMessage({ id, result: execute(operation, args), milliseconds: performance.now() - start });
  } catch (error) {
    self.postMessage({ id, error: error.message || 'The engine could not process this input.' });
  }
};
self.postMessage({ ready: true });
