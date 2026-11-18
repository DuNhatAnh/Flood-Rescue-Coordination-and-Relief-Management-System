// Bruno runner tối giản (định dạng OpenCollection YAML của Bruno v4) — chạy cả collection trên BACKEND THẬT, xuất JSON kết quả.
// Dùng khi máy không có Bruno CLI. Thứ tự chạy theo seq của folder và request như Bruno Runner.
// Cách chạy (từ thư mục gốc repo, cần `npm install` trong test-automation trước):
//   node qa-testing/scripts/bruno_runner.js "Flood Rescue Coordination & Relief Management API" qa-testing/reports/bruno_results.json [Folder...]
const path = require('path');
const fs = require('fs');
const NM = path.join(__dirname, '..', '..', 'test-automation', 'node_modules') + path.sep;
const yaml = require(NM + 'js-yaml');
const axios = require(NM + 'axios');
const assert = require('assert');

const [dir, outFile, ...only] = process.argv.slice(2);
const coll = yaml.load(fs.readFileSync(path.join(dir, 'opencollection.yml'), 'utf8'));
const env = yaml.load(fs.readFileSync(path.join(dir, 'environments/Local.yml'), 'utf8'));
const vars = {};
for (const v of (coll.request && coll.request.variables) || []) vars[v.name] = v.value;
for (const v of env.variables || []) vars[v.name] = v.value;
const runtime = {};
const get = k => (k in runtime ? runtime[k] : vars[k]);
const interp = s => typeof s === 'string' ? s.replace(/\{\{\s*([\w.$-]+)\s*\}\}/g, (m, k) => {
  if (k === '$timestamp') return String(Date.now());
  const v = get(k); return v === undefined ? m : String(v);
}) : s;

function expect(actual) {
  const api = {
    equal: e => assert.deepStrictEqual(actual, e, `expected ${JSON.stringify(actual)} to equal ${JSON.stringify(e)}`),
    include: e => {
      if (typeof actual === 'string') assert.ok(actual.includes(e), `expected "${actual}" to include "${e}"`);
      else assert.ok(Array.isArray(actual) && actual.some(x => JSON.stringify(x) === JSON.stringify(e)), `expected ${JSON.stringify(actual)} to include ${JSON.stringify(e)}`);
    },
    oneOf: arr => assert.ok(arr.includes(actual), `expected ${actual} to be one of [ ${arr.join(', ')} ]`),
    property: p => assert.ok(actual != null && Object.prototype.hasOwnProperty.call(actual, p), `expected object to have property ${p}`),
    a: t => assert.ok(t === 'array' ? Array.isArray(actual) : typeof actual === t, `expected ${typeof actual} to be a ${t}`),
  };
  api.include.members = arr => arr.forEach(x => assert.ok(actual.includes(x), `missing member ${x}`));
  const to = { equal: api.equal, include: api.include, have: { property: api.property },
    be: { oneOf: api.oneOf, a: api.a, an: api.a } };
  Object.defineProperty(to.be, 'true', { get: () => assert.strictEqual(actual, true, `expected ${actual} to be true`) });
  Object.defineProperty(to.be, 'false', { get: () => assert.strictEqual(actual, false, `expected ${actual} to be false`) });
  Object.defineProperty(to.be, 'undefined', { get: () => assert.strictEqual(actual, undefined, `expected ${actual} to be undefined`) });
  return { to };
}

const bru = {
  setVar: (k, v) => { runtime[k] = v; }, getVar: k => runtime[k],
  setEnvVar: (k, v) => { runtime[k] = v; }, getEnvVar: k => get(k),
  setCollectionVar: (k, v) => { runtime[k] = v; },
};

function folders() {
  return fs.readdirSync(dir, { withFileTypes: true })
    .filter(d => d.isDirectory() && d.name !== 'environments' && fs.existsSync(path.join(dir, d.name, 'folder.yml')))
    .map(d => ({ name: d.name, meta: yaml.load(fs.readFileSync(path.join(dir, d.name, 'folder.yml'), 'utf8')) }))
    .sort((a, b) => (a.meta.info.seq || 0) - (b.meta.info.seq || 0));
}

async function runRequest(folder, file) {
  const doc = yaml.load(fs.readFileSync(file, 'utf8'));
  const h = doc.http || {};
  const result = { folder, name: doc.info.name, file: path.basename(file), method: h.method, tests: [] };
  const scripts = (doc.runtime && doc.runtime.scripts) || [];
  const run = (code, res) => {
    const tests = [];
    const test = (name, fn) => { try { fn(); tests.push({ name, ok: true }); } catch (e) { tests.push({ name, ok: false, err: e.message }); } };
    const req = { setHeader: () => {}, getUrl: () => url };
    // eslint-disable-next-line no-new-func
    new Function('test', 'expect', 'bru', 'res', 'req', 'console', code)(test, expect, bru, res, req, { log: () => {} });
    return tests;
  };
  for (const s of scripts.filter(s => s.type === 'before-request')) { try { run(s.code, null); } catch (e) { result.preErr = e.message; } }

  let url = interp(h.url);
  for (const p of (h.params || []).filter(p => p.type === 'path')) url = url.replace(':' + p.name, encodeURIComponent(interp(String(p.value))));
  const headers = {};
  for (const x of h.headers || []) if (!x.disabled) headers[x.name] = interp(x.value);
  const authMode = h.auth === undefined ? 'none' : h.auth;
  if (authMode === 'inherit' && !Object.keys(headers).some(k => k.toLowerCase() === 'authorization')) headers.Authorization = 'Bearer ' + get('bearerToken');
  let data;
  if (h.body && h.body.data !== undefined) { const raw = interp(h.body.data); try { data = JSON.parse(raw); } catch { data = raw; } }
  result.url = url.replace(vars.baseUrl, '');
  let resp;
  try {
    resp = await axios({ method: h.method, url, headers, data, validateStatus: () => true, timeout: 15000 });
  } catch (e) { result.netErr = e.message; return result; }
  result.status = resp.status;
  const res = { getStatus: () => resp.status, getBody: () => resp.data, getHeader: k => resp.headers[k.toLowerCase()], status: resp.status, body: resp.data };
  for (const s of scripts.filter(s => s.type === 'after-response')) {
    try { result.tests.push(...run(s.code, res)); } catch (e) { result.tests.push({ name: 'script', ok: false, err: 'Script error: ' + e.message }); }
  }
  result.message = resp.data && resp.data.message;
  return result;
}

(async () => {
  const out = [];
  for (const f of folders()) {
    if (only.length && !only.includes(f.name)) continue;
    const files = fs.readdirSync(path.join(dir, f.name)).filter(n => n.endsWith('.yml') && n !== 'folder.yml')
      .map(n => ({ n, seq: (yaml.load(fs.readFileSync(path.join(dir, f.name, n), 'utf8')).info || {}).seq || 0 }))
      .sort((a, b) => a.seq - b.seq);
    for (const { n } of files) out.push(await runRequest(f.name, path.join(dir, f.name, n)));
  }
  fs.writeFileSync(outFile, JSON.stringify(out, null, 1));
  const failed = out.filter(r => r.netErr || r.tests.some(t => !t.ok));
  const noTests = out.filter(r => !r.netErr && r.tests.length === 0);
  console.log(`requests=${out.length} pass=${out.length - failed.length - noTests.length} fail=${failed.length} no-assertions=${noTests.length}`);
})();
