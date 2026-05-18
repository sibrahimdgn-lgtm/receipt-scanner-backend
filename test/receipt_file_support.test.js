const test = require('node:test');
const assert = require('node:assert/strict');

const { buildReceiptPrompt } = require('../src/services/geminiService');
const {
  getReceiptUploadMessage,
  isPdfReceiptMimeType,
  normalizeReceiptMimeType,
} = require('../src/config/receiptFiles');

test('normalizes PDF receipt uploads from file extension fallback', () => {
  assert.equal(
    normalizeReceiptMimeType('application/octet-stream', 'invoice.pdf'),
    'application/pdf'
  );
  assert.equal(
    normalizeReceiptMimeType('image/png', 'receipt.png'),
    'image/png'
  );
  assert.equal(isPdfReceiptMimeType('application/pdf'), true);
});

test('returns localized upload errors for supported backend languages', () => {
  assert.equal(
    getReceiptUploadMessage('unsupportedFileType', 'tr'),
    'Sadece resim ve PDF dosyalari yuklenebilir.'
  );
  assert.equal(
    getReceiptUploadMessage('unsupportedFileType', 'en'),
    'Only image and PDF files can be uploaded.'
  );
  assert.equal(
    getReceiptUploadMessage('unsupportedFileType', 'de'),
    'Nur Bild- und PDF-Dateien koennen hochgeladen werden.'
  );
  assert.equal(
    getReceiptUploadMessage('unsupportedFileType', 'ar'),
    'يمكن تحميل ملفات الصور وPDF فقط.'
  );
});

test('builds a Qwen prompt that explicitly accepts PDF receipts', () => {
  const prompt = buildReceiptPrompt('en');

  assert.match(prompt, /PDF file/i);
  assert.match(prompt, /pure JSON only/i);
});
