// EXAMPLE ONLY - adapt to your real backend (DB calls are placeholders).
// npm i multer
const express = require('express');
const multer = require('multer');
const fs = require('fs/promises');
const path = require('path');
const { runAutoVerification } = require('./autoVerify');

const router = express.Router();
const upload = multer({
  dest: path.join(__dirname, 'private_uploads/verification'), // NOT a public/static folder
  limits: { fileSize: 8 * 1024 * 1024, files: 4 },
  fileFilter: (_req, file, cb) => cb(null, /^image\//.test(file.mimetype)),
});

const fields = [
  { name: 'front', maxCount: 1 },
  { name: 'back', maxCount: 1 },
  { name: 'selfie_front', maxCount: 1 },
  { name: 'selfie_back', maxCount: 1 },
];

// ---- USER: submit ---------------------------------------------------------
// requireAuth = your existing auth middleware (sets req.user)
router.post('/verification/submit', requireAuth, upload.fields(fields), async (req, res) => {
  const b = req.body;
  const f = req.files || {};
  const type = b.documentType;
  if (!['nic', 'driving_license', 'passport'].includes(type))
    return res.status(400).json({ error: 'Invalid document type' });
  if (!f.front || !f.selfie_front || (type === 'nic' && (!f.back || !f.selfie_back)))
    return res.status(400).json({ error: 'Missing photos' });
  if (!/^(\d{9}[VvXx]|\d{12})$/.test(b.nicNumber || ''))
    return res.status(400).json({ error: 'Invalid NIC number' });

  // TODO: reject if user.verifiedStatus is 'pending' or 'verified'
  // TODO: reject if another user already has this nicNumber (except this user)
  const paths = Object.values(f).map((arr) => arr[0].path);
  const details = {
    fullName: b.fullName, birthday: b.birthday, nicNumber: b.nicNumber.toUpperCase(),
    address: b.address, province: b.province, district: b.district, documentType: type,
  };
  const files = Object.fromEntries(Object.entries(f).map(([k, arr]) => [k, arr[0].path]));

  // ---- AUTOMATIC CHECK (OCR + face match) ----
  let result;
  try {
    result = await runAutoVerification({ details, files });
  } catch (e) {
    result = { decision: 'review', reason: 'auto check error', checks: {} };
  }
  console.log('auto-verify', req.user.id, result.decision, JSON.stringify(result.checks));

  if (result.decision === 'approve') {
    // TODO: save record (details + paths + result.checks), status 'approved'
    // TODO: user.verifiedStatus = 'verified'; notify (type 'verification_approved')
    return res.json({ ok: true, verifiedStatus: 'verified' });
  }
  if (result.decision === 'reject') {
    for (const p of paths) { try { await fs.unlink(p); } catch (_) {} } // delete photos
    // TODO: save record with status 'rejected' + rejectionReason = result.reason (no photo paths)
    // TODO: user.verifiedStatus = 'rejected'; notify (type 'verification_rejected')
    return res.json({ ok: true, verifiedStatus: 'rejected', rejectionReason: result.reason });
  }
  // 'review' -> unsure, an admin decides (admin approve/reject routes below)
  // TODO: save record (details + paths + result.checks), status 'pending'; user.verifiedStatus = 'pending'
  return res.json({ ok: true, verifiedStatus: 'pending' });
});

// ---- USER: status  (extend your existing GET /verification/status) ---------
// return { verifiedStatus, documentType, rejectionReason }

// ---- ADMIN: view photos (auth-protected, never public) ---------------------
// router.get('/admin/verification/:id/photo/:key', requireAdmin, ...) -> res.sendFile(...)

// ---- ADMIN: approve --------------------------------------------------------
router.post('/admin/verification/:id/approve', requireAdmin, async (req, res) => {
  // TODO: record.status = 'approved'; user.verifiedStatus = 'verified'
  // TODO: notify user (type: 'verification_approved')
  res.json({ ok: true });
});

// ---- ADMIN: reject  -> photos are DELETED, user sees "Re-upload" -----------
router.post('/admin/verification/:id/reject', requireAdmin, async (req, res) => {
  const reason = (req.body.reason || '').toString().slice(0, 300);
  // TODO: const rec = await db.getVerification(req.params.id);
  const rec = { files: [] }; // <- replace: array of stored file paths for this record
  for (const p of rec.files) {
    try { await fs.unlink(p); } catch (_) {}
  }
  // TODO: record.files = []; record.status = 'rejected'; record.rejectionReason = reason;
  //       user.verifiedStatus = 'rejected'
  // TODO: notify user (type: 'verification_rejected') - your app already handles this type
  res.json({ ok: true });
});

module.exports = router;
