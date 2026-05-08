const test = require('node:test');
const assert = require('node:assert/strict');

const {
  buildLocalStoredPath,
  buildLocalUploadUrl,
  extractLocalUploadPath,
  isLocalStoredPath,
} = require('../src/config/runtimePaths');

test('local upload helpers generate stable stored paths and URLs', () => {
  const relativePath = 'shops/shop-1/receipts/demo file.pdf';
  const storedPath = buildLocalStoredPath(relativePath);

  assert.equal(storedPath, 'local:shops/shop-1/receipts/demo file.pdf');
  assert.equal(isLocalStoredPath(storedPath), true);
  assert.equal(
    extractLocalUploadPath(storedPath),
    'shops/shop-1/receipts/demo file.pdf'
  );
  assert.match(
    buildLocalUploadUrl(relativePath),
    /http:\/\/127\.0\.0\.1:3000\/uploads\/shops\/shop-1\/receipts\/demo%20file\.pdf$/
  );
});
