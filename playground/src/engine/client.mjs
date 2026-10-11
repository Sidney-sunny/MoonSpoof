// Request correlation, lifecycle, and failure recovery stay outside components.
export class EngineClient {
  constructor(createWorker, timeout = 30_000) {
    this.createWorker = createWorker;
    this.timeout = timeout;
    this.pending = new Map();
    this.nextId = 0;
    this.worker = null;
  }

  ready() {
    if (this.boot) return this.boot;
    this.boot = new Promise((resolve, reject) => {
      this.bootReject = reject;
      this.bootTimer = setTimeout(() => this.fail(new Error('Engine startup timed out. Retry the engine.')), this.timeout);
      try {
        this.worker = this.createWorker();
        this.worker.onmessage = ({ data }) => {
          if (data.ready) {
            clearTimeout(this.bootTimer);
            this.bootReject = null;
            resolve();
            return;
          }
          const request = this.pending.get(data.id);
          if (!request) return;
          clearTimeout(request.timer);
          this.pending.delete(data.id);
          if (data.error) request.reject(new Error(data.error));
          else request.resolve({ data: data.result, milliseconds: data.milliseconds });
        };
        this.worker.onerror = event => {
          event.preventDefault?.();
          this.fail(new Error('Engine worker failed. Retry the engine.'));
        };
        this.worker.onmessageerror = () => this.fail(new Error('Engine response could not be decoded. Retry the engine.'));
      } catch (error) { this.fail(error); }
    });
    // A failed constructor must not leave a cached rejected startup promise.
    const boot = this.boot;
    boot.catch(() => { if (this.boot === boot) this.boot = null; });
    return boot;
  }

  async request(operation, args) {
    await this.ready();
    return new Promise((resolve, reject) => {
      const id = ++this.nextId;
      const timer = setTimeout(() => this.fail(new Error('Scan timed out. Shorten the input and retry.')), this.timeout);
      this.pending.set(id, { resolve, reject, timer });
      try { this.worker.postMessage({ id, operation, args }); }
      catch (error) { this.fail(error); }
    });
  }

  fail(error) {
    clearTimeout(this.bootTimer);
    this.bootReject?.(error);
    this.bootReject = null;
    for (const request of this.pending.values()) {
      clearTimeout(request.timer);
      request.reject(error);
    }
    this.pending.clear();
    this.worker?.terminate();
    this.worker = null;
    this.boot = null;
  }

  dispose() { this.fail(new Error('Engine session closed.')); }
}
