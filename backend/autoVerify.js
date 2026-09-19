// Automatic verification: OCR + face match + NIC/birthday consistency.
// Uses AWS Rekognition (DetectText + CompareFaces). npm i @aws-sdk/client-rekognition
// Env: AWS_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
//      FACE_APPROVE (default 90), FACE_REJECT (default 50)
const fs = require('fs/promises');

const FACE_APPROVE = Number(process.env.FACE_APPROVE || 90);
const FACE_REJECT = Number(process.env.FACE_REJECT || 50);
const MAX_BYTES = 5 * 1024 * 1024; // Rekognition limit for raw bytes

// ------------------------------------------------------------------ NIC helpers
function isLeap(y) {
  return (y % 4 === 0 && y % 100 !== 0) || y % 400 === 0;
}

/** Decode Sri Lankan NIC -> { birthday:'YYYY-MM-DD', gender:'M'|'F' } or null. */
function decodeNic(nic) {
  const s = String(nic || '').trim().toUpperCase();
  let year, days;
  if (/^\d{9}[VX]$/.test(s)) {
    year = 1900 + Number(s.slice(0, 2));
    days = Number(s.slice(2, 5));
  } else if (/^\d{12}$/.test(s)) {
    year = Number(s.slice(0, 4));
    days = Number(s.slice(4, 7));
  } else return null;

  let gender = 'M';
  if (days > 500) {
    gender = 'F';
    days -= 500;
  }
  // NIC numbering always counts Feb as 29 days.
  if (!isLeap(year) && days > 60) days -= 1;
  if (days < 1 || days > 366 || (!isLeap(year) && days > 365)) return null;

  const d = new Date(Date.UTC(year, 0, 1));
  d.setUTCDate(d.getUTCDate() + days - 1);
  if (d.getUTCFullYear() !== year) return null;
  return { birthday: d.toISOString().slice(0, 10), gender };
}

function nicCore(nic) {
  return String(nic || '').replace(/[^0-9]/g, ''); // digits only (ignore V/X)
}

// ------------------------------------------------------------------ OCR text helpers
const DIGIT_FIX = { O: '0', Q: '0', D: '0', I: '1', L: '1', S: '5', B: '8', Z: '2' };

function alnum(s) {
  return String(s || '').toUpperCase().replace(/[^A-Z0-9]/g, '');
}

/** True if the NIC digits appear in the OCR text (tolerates common OCR letter/digit mix-ups). */
function textHasNic(ocrText, nic) {
  const core = nicCore(nic);
  if (!core) return false;
  const plain = alnum(ocrText);
  if (plain.includes(core)) return true;
  const fixed = plain.replace(/[OQDILSBZ]/g, (c) => DIGIT_FIX[c]);
  return fixed.includes(core);
}

function tokens(s) {
  return String(s || '')
    .toUpperCase()
    .replace(/[^A-Z\s]/g, ' ')
    .split(/\s+/)
    .filter((t) => t.length >= 2);
}

function lev(a, b) {
  const m = a.length, n = b.length;
  const dp = Array.from({ length: m + 1 }, (_, i) => [i, ...Array(n).fill(0)]);
  for (let j = 0; j <= n; j++) dp[0][j] = j;
  for (let i = 1; i <= m; i++)
    for (let j = 1; j <= n; j++)
      dp[i][j] = Math.min(
        dp[i - 1][j] + 1,
        dp[i][j - 1] + 1,
        dp[i - 1][j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1)
      );
  return dp[m][n];
}

/** Fraction (0..1) of the user's name words found in the OCR text. */
function nameScore(fullName, ocrText) {
  const want = tokens(fullName);
  if (!want.length) return 0;
  const have = tokens(ocrText);
  let hit = 0;
  for (const w of want) {
    const ok = have.some((h) => h === w || (w.length >= 5 && lev(h, w) <= 1));
    if (ok) hit++;
  }
  return hit / want.length;
}

// ------------------------------------------------------------------ Rekognition
let _client;
function rek() {
  if (!_client) {
    const { RekognitionClient } = require('@aws-sdk/client-rekognition');
    _client = new RekognitionClient({ region: process.env.AWS_REGION || 'ap-south-1' });
  }
  return _client;
}

async function readBytes(p) {
  const buf = await fs.readFile(p);
  if (buf.length > MAX_BYTES) throw new Error('image too large');
  return buf;
}

const defaultProvider = {
  async detectText(bytes) {
    const { DetectTextCommand } = require('@aws-sdk/client-rekognition');
    const out = await rek().send(new DetectTextCommand({ Image: { Bytes: bytes } }));
    return (out.TextDetections || [])
      .filter((t) => t.Type === 'LINE')
      .map((t) => t.DetectedText)
      .join('\n');
  },
  /** returns best similarity 0..100, or null if a face could not be found. */
  async compareFaces(sourceBytes, targetBytes) {
    const { CompareFacesCommand } = require('@aws-sdk/client-rekognition');
    try {
      const out = await rek().send(
        new CompareFacesCommand({
          SourceImage: { Bytes: sourceBytes },
          TargetImage: { Bytes: targetBytes },
          SimilarityThreshold: 0,
        })
      );
      const sims = (out.FaceMatches || []).map((m) => m.Similarity || 0);
      return sims.length ? Math.max(...sims) : null;
    } catch (e) {
      if (e.name === 'InvalidParameterException') return null; // no face in source
      throw e;
    }
  },
};

// ------------------------------------------------------------------ main
/**
 * @param {object} p
 *  details: { fullName, birthday:'YYYY-MM-DD', nicNumber, documentType }
 *  files:   { front, selfie_front, back?, selfie_back? }  (absolute paths)
 *  provider: optional (for tests)
 * @returns {{decision:'approve'|'reject'|'review', reason?:string, checks:object}}
 */
async function runAutoVerification({ details, files, provider = defaultProvider }) {
  const checks = {};
  const type = details.documentType;

  // 1) NIC number <-> birthday (no OCR needed)
  const decoded = decodeNic(details.nicNumber);
  checks.nicValid = !!decoded;
  checks.dobMatchesNic = decoded ? decoded.birthday === details.birthday : false;
  if (!decoded)
    return { decision: 'reject', reason: 'The NIC number is not valid.', checks };
  if (!checks.dobMatchesNic)
    return { decision: 'reject', reason: 'Your birthday does not match your NIC number.', checks };

  // 2) read images
  let front, selfieF, selfieB;
  try {
    front = await readBytes(files.front);
    selfieF = await readBytes(files.selfie_front);
    if (type === 'nic') selfieB = await readBytes(files.selfie_back);
  } catch (e) {
    return { decision: 'review', reason: 'Could not read images', checks };
  }

  // 3) OCR on the document
  let text = '';
  try {
    text = await provider.detectText(front);
  } catch (e) {
    return { decision: 'review', reason: 'OCR failed', checks };
  }
  checks.nicOnDoc = textHasNic(text, details.nicNumber);
  checks.nameScore = nameScore(details.fullName, text);

  // 4) face match: live selfie vs document photo
  try {
    checks.faceDoc = await provider.compareFaces(selfieF, front);
    if (type === 'nic') checks.faceSelfies = await provider.compareFaces(selfieF, selfieB);
  } catch (e) {
    return { decision: 'review', reason: 'Face match failed', checks };
  }

  // clear failures -> reject
  if (checks.faceDoc !== null && checks.faceDoc < FACE_REJECT)
    return { decision: 'reject', reason: 'Your face does not match the photo on your document.', checks };
  if (type === 'nic' && checks.faceSelfies !== null && checks.faceSelfies < FACE_REJECT)
    return { decision: 'reject', reason: 'The two face checks do not match each other.', checks };

  // everything must pass to auto-approve
  const faceOk = checks.faceDoc !== null && checks.faceDoc >= FACE_APPROVE;
  const selfiesOk = type !== 'nic' || (checks.faceSelfies !== null && checks.faceSelfies >= FACE_APPROVE);
  const docOk = type === 'passport' ? checks.nameScore >= 0.8 : checks.nicOnDoc === true;

  if (faceOk && selfiesOk && docOk) return { decision: 'approve', checks };

  // unsure (blurry photo, glare, OCR miss...) -> admin decides
  return { decision: 'review', reason: 'Needs manual review', checks };
}

module.exports = { runAutoVerification, decodeNic, textHasNic, nameScore };
