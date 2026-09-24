const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { runAutoVerification, decodeNic, textHasNic, nameScore } = require('./autoVerify');

// --- NIC decoding (old: YY DDD + 4 digits + V ; new: YYYY DDD + 5 digits)
assert.deepStrictEqual(decodeNic('900010000V'), { birthday: '1990-01-01', gender: 'M' });
assert.deepStrictEqual(decodeNic('900610000V'), { birthday: '1990-03-01', gender: 'M' }); // 1990 not leap: day 61 = Mar 1
assert.deepStrictEqual(decodeNic('200006000000'), { birthday: '2000-02-29', gender: 'M' }); // leap year, day 60
assert.deepStrictEqual(decodeNic('200006100000'), { birthday: '2000-03-01', gender: 'M' }); // leap year, day 61
assert.deepStrictEqual(decodeNic('199950100000'), { birthday: '1999-01-01', gender: 'F' });
assert.deepStrictEqual(decodeNic('905010000V'), { birthday: '1990-01-01', gender: 'F' });
assert.strictEqual(decodeNic('12345'), null);
assert.strictEqual(decodeNic('199936700000'), null); // day 367 invalid
assert.strictEqual(decodeNic('199900000000'), null); // day 0 invalid

// --- OCR text
assert(textHasNic('NAME\n1990 0010 0000\nSRI LANKA', '199000100000'));
assert(textHasNic('No: 9OOO1OOOOV', '900010000V')); // O read instead of 0
assert(!textHasNic('987654321V', '900010000V'));

// --- name score
assert.strictEqual(nameScore('Kasun Perera', 'NAME: KASUN PERERA'), 1);
assert.strictEqual(nameScore('Kasun Perera', 'KASUM PERERA'), 1); // 1 typo tolerated
assert.strictEqual(nameScore('Kasun Perera', 'JOHN SMITH'), 0);

// --- decisions with a fake provider
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'v-'));
const mk = (n) => { const p = path.join(tmp, n); fs.writeFileSync(p, 'x'); return p; };
const files = { front: mk('f'), selfie_front: mk('sf'), back: mk('b'), selfie_back: mk('sb') };
const details = { fullName: 'Kasun Perera', birthday: '1990-01-01', nicNumber: '900010000V', documentType: 'nic' };
const prov = (text, sims) => ({
  detectText: async () => text,
  compareFaces: async () => sims.shift(),
});

(async () => {
  let r = await runAutoVerification({ details, files, provider: prov('900010000V KASUN', [97, 95]) });
  assert.strictEqual(r.decision, 'approve');

  r = await runAutoVerification({ details, files, provider: prov('900010000V', [30, 95]) });
  assert.strictEqual(r.decision, 'reject');

  r = await runAutoVerification({ details, files, provider: prov('blurry', [97, 95]) });
  assert.strictEqual(r.decision, 'review'); // number not readable

  r = await runAutoVerification({ details, files, provider: prov('900010000V', [null, 95]) });
  assert.strictEqual(r.decision, 'review'); // no face found in doc photo

  r = await runAutoVerification({ details: { ...details, birthday: '1991-01-01' }, files, provider: prov('900010000V', [97, 95]) });
  assert.strictEqual(r.decision, 'reject'); // birthday mismatch

  const dl = { ...details, documentType: 'driving_license' };
  r = await runAutoVerification({ details: dl, files, provider: prov('ID 900010000V', [92]) });
  assert.strictEqual(r.decision, 'approve');

  const pp = { ...details, documentType: 'passport' };
  r = await runAutoVerification({ details: pp, files, provider: prov('PERERA KASUN', [93]) });
  assert.strictEqual(r.decision, 'approve');
  r = await runAutoVerification({ details: pp, files, provider: prov('SOMEONE ELSE', [93]) });
  assert.strictEqual(r.decision, 'review');

  console.log('ALL TESTS PASSED');
})().catch((e) => { console.error(e); process.exit(1); });
