/**
 * Receipt Scanner API — Entry Point
 *
 * Multi-tenant receipt scanning server powered by Google Gemini AI.
 * Accepts image/PDF uploads, stores files in Firebase Cloud Storage,
 * and persists tenant data in Firestore.
 */

require('dotenv').config();

const fs = require('fs');
const express = require('express');
const cors = require('cors');
const receiptRoutes   = require('./src/routes/receipts');
const authRoutes      = require('./src/routes/auth');
const dashboardRoutes = require('./src/routes/dashboard');
const {
  ensureFirebaseAdmin,
  getFirebaseAdminDiagnostics,
  hasFirebaseAdminConfig,
} = require('./src/config/firebaseAdmin');
const { hasGeminiApiKey } = require('./src/services/geminiService');
const { ensureUploadsDir, UPLOADS_ROOT } = require('./src/config/runtimePaths');

const app = express();
const PORT = process.env.PORT || 3000;

bootstrapRuntime();

// ── CORS (allows Flutter web on a different port) ─────────────
app.use(cors());

// ── Body parsers ──────────────────────────────────────────────
app.use(express.json());

// ── Local uploads fallback ────────────────────────────────────
app.use('/uploads', express.static(UPLOADS_ROOT));

// ── Health check ──────────────────────────────────────────────
app.get('/api/health', (_req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    firebaseAdminConfigured: hasFirebaseAdminConfig(),
    firebaseStorageBucket: getFirebaseAdminDiagnostics().storageBucket,
    geminiConfigured: hasGeminiApiKey(),
    uploadsFallbackReady: true,
  });
});

// ── Routes ────────────────────────────────────────────────────
app.use('/api/auth',      authRoutes);
app.use('/api/receipts',  receiptRoutes);
app.use('/api/dashboard', dashboardRoutes);

// ── 404 handler ───────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: 'Route not found.' });
});

// ── Global error handler ──────────────────────────────────────
app.use((err, req, res, _next) => {
  // Multer file-size / file-type errors
  if (
    err.name === 'MulterError' ||
    err.code === 'UNSUPPORTED_RECEIPT_FILE' ||
    err.statusCode === 400
  ) {
    return res.status(400).json({ error: err.message });
  }

  console.error(`[Error] ${req.method} ${req.originalUrl}`);
  console.error(err);

  res.status(500).json({
    error: 'Internal server error. Please try again later.',
  });
});

// ── Start server ──────────────────────────────────────────────
app.listen(PORT, () => {
  const firebaseDiagnostics = getFirebaseAdminDiagnostics();

  console.log(`\n🧾 Receipt Scanner API listening on http://localhost:${PORT}`);
  console.log(`   Firebase Admin configured: ${hasFirebaseAdminConfig() ? 'yes' : 'no'}`);
  console.log(`   Firebase credential source: ${firebaseDiagnostics.credentialSource}`);
  console.log(
    `   Firebase service account path: ${
      firebaseDiagnostics.credentialsPath || '(env/json)'
    }`
  );
  console.log(`   Firebase storage bucket: ${firebaseDiagnostics.storageBucket || '(not set)'}`);
  console.log(`   Gemini API configured: ${hasGeminiApiKey() ? 'yes' : 'no'}`);
  console.log(`   Local uploads fallback: ${UPLOADS_ROOT}`);
  console.log(`   POST /api/auth/register     — bootstrap Firestore account`);
  console.log(`   POST /api/auth/login        — verify Firebase session`);
  console.log(`   POST /api/receipts/scan     — scan a receipt`);
  console.log(`   GET  /api/dashboard/summary — spending summary`);
  console.log(`   GET  /api/dashboard/history — receipt history`);
  console.log(`   GET  /api/health            — health check\n`);
});

process.on('unhandledRejection', (reason) => {
  console.error('[UnhandledRejection]');
  console.error(reason);
});

process.on('uncaughtException', (error) => {
  console.error('[UncaughtException]');
  console.error(error);
});

function bootstrapRuntime() {
  const uploadsDir = ensureUploadsDir();
  fs.accessSync(uploadsDir, fs.constants.R_OK | fs.constants.W_OK);
  ensureFirebaseAdmin();
}
