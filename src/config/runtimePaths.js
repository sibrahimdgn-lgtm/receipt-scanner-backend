const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.resolve(__dirname, '../..');
const UPLOADS_ROOT = path.join(PROJECT_ROOT, 'uploads');
const LOCAL_UPLOAD_PREFIX = 'local:';

function ensureUploadsDir() {
  fs.mkdirSync(UPLOADS_ROOT, { recursive: true });
  fs.accessSync(UPLOADS_ROOT, fs.constants.R_OK | fs.constants.W_OK);
  return UPLOADS_ROOT;
}

function encodePathForUrl(relativePath) {
  return relativePath
    .split('/')
    .filter(Boolean)
    .map(encodeURIComponent)
    .join('/');
}

function normalizeRelativeUploadPath(relativePath) {
  return relativePath.replace(/\\/g, '/').replace(/^\/+/, '');
}

function buildLocalUploadUrl(relativePath) {
  const normalizedPath = normalizeRelativeUploadPath(relativePath);
  const baseUrl =
    process.env.PUBLIC_API_BASE_URL?.trim()
    || `http://127.0.0.1:${process.env.PORT || 3000}`;

  return `${baseUrl.replace(/\/+$/, '')}/uploads/${encodePathForUrl(
    normalizedPath
  )}`;
}

function buildLocalStoredPath(relativePath) {
  return `${LOCAL_UPLOAD_PREFIX}${normalizeRelativeUploadPath(relativePath)}`;
}

function isLocalStoredPath(storedPath) {
  return (
    typeof storedPath === 'string'
    && storedPath.startsWith(LOCAL_UPLOAD_PREFIX)
  );
}

function extractLocalUploadPath(storedPath) {
  if (!isLocalStoredPath(storedPath)) {
    return null;
  }

  return storedPath.slice(LOCAL_UPLOAD_PREFIX.length);
}

function resolveLocalUploadAbsolutePath(relativePath) {
  return path.join(UPLOADS_ROOT, normalizeRelativeUploadPath(relativePath));
}

module.exports = {
  LOCAL_UPLOAD_PREFIX,
  PROJECT_ROOT,
  UPLOADS_ROOT,
  buildLocalStoredPath,
  buildLocalUploadUrl,
  ensureUploadsDir,
  extractLocalUploadPath,
  isLocalStoredPath,
  normalizeRelativeUploadPath,
  resolveLocalUploadAbsolutePath,
};
