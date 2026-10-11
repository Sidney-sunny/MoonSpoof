import { test } from 'node:test';
import assert from 'node:assert/strict';
import { EngineClient } from '../src/engine/client.mjs';

class WorkerDouble {
  constructor() { this.sent = []; this.terminated = false; }
  postMessage(message) { this.sent.push(message); }
  terminate() { this.terminated = true; }
  deliver(data) { this.onmessage({ data }); }
}

test('worker responses correlate correctly even when they arrive out of order', async () => {
  const worker = new WorkerDouble();
  const client = new EngineClient(() => worker);
  const ready = client.ready(); worker.deliver({ ready: true }); await ready;
  const first = client.request('inspect', { input: 'one' });
  const second = client.request('inspect', { input: 'two' });
  await Promise.resolve();
  worker.deliver({ id: worker.sent[1].id, result: 'two', milliseconds: 1 });
  worker.deliver({ id: worker.sent[0].id, result: 'one', milliseconds: 2 });
  assert.equal((await first).data, 'one'); assert.equal((await second).data, 'two');
  assert.equal(client.pending.size, 0); client.dispose();
});

test('worker failure rejects outstanding work and allows a fresh startup', async () => {
  const workers = [];
  const client = new EngineClient(() => { const worker = new WorkerDouble(); workers.push(worker); return worker; });
  const firstBoot = client.ready(); workers[0].deliver({ ready: true }); await firstBoot;
  const pending = client.request('inspect', { input: 'one' }); await Promise.resolve();
  const failure = assert.rejects(pending, /worker failed/);
  workers[0].onerror({ preventDefault() {} }); await failure;
  assert.equal(workers[0].terminated, true);
  const secondBoot = client.ready(); workers[1].deliver({ ready: true }); await secondBoot;
  assert.equal(workers.length, 2); client.dispose();
});

test('startup timeout terminates a worker that never becomes ready', async () => {
  const worker = new WorkerDouble();
  const client = new EngineClient(() => worker, 10);
  await assert.rejects(client.ready(), /startup timed out/);
  assert.equal(worker.terminated, true); assert.equal(client.pending.size, 0);
});

test('constructor errors recover instead of retaining a rejected promise', async () => {
  let count = 0;
  const worker = new WorkerDouble();
  const client = new EngineClient(() => { if (++count === 1) throw new Error('Construction failed'); return worker; });
  await assert.rejects(client.ready(), /Construction/);
  const next = client.ready(); worker.deliver({ ready: true }); await next;
  assert.equal(count, 2); client.dispose();
});

test('request timeout rejects all pending work and discards the stalled worker', async () => {
  const worker = new WorkerDouble();
  const client = new EngineClient(() => worker, 20);
  const ready = client.ready(); worker.deliver({ ready: true }); await ready;
  await assert.rejects(client.request('batch', { input: 'a' }), /Scan timed out/);
  assert.equal(worker.terminated, true); assert.equal(client.pending.size, 0);
});
