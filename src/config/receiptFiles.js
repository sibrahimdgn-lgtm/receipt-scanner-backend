const { DEFAULT_LANGUAGE, normalizeLanguageCode } = require('./languages');

const RECEIPT_EXTENSION_TO_MIME = {
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.heic': 'image/heic',
  '.heif': 'image/heif',
  '.pdf': 'application/pdf',
};

const RECEIPT_MIME_ALIASES = {
  'image/heic-sequence': 'image/heic',
  'image/heif-sequence': 'image/heif',
};

const SUPPORTED_RECEIPT_MIME_TYPES = Array.from(
  new Set(Object.values(RECEIPT_EXTENSION_TO_MIME))
);
const SUPPORTED_RECEIPT_EXTENSIONS = Object.keys(RECEIPT_EXTENSION_TO_MIME);
const MAX_RECEIPT_FILE_SIZE = 10 * 1024 * 1024; // 10 MB

const RECEIPT_UPLOAD_MESSAGES = {
  unsupportedFileType: {
    tr: 'Sadece resim ve PDF dosyalari yuklenebilir.',
    en: 'Only image and PDF files can be uploaded.',
    de: 'Nur Bild- und PDF-Dateien koennen hochgeladen werden.',
    ar: 'يمكن تحميل ملفات الصور وPDF فقط.',
  },
  missingFile: {
    tr: 'Fis alani altinda bir resim veya PDF yukleyin.',
    en: 'Upload an image or PDF under the "receipt" field.',
    de: 'Lade im Feld "receipt" ein Bild oder eine PDF hoch.',
    ar: 'ارفع صورة أو ملف PDF ضمن الحقل "receipt".',
  },
};

function getReceiptExtension(filename = '') {
  const normalized = filename.toString().trim().toLowerCase();
  if (!normalized.includes('.')) {
    return '';
  }

  return `.${normalized.split('.').pop()}`;
}

function normalizeReceiptMimeType(mimeType, filename = '') {
  const normalizedMimeType = mimeType?.toString().trim().toLowerCase();
  const canonicalMimeType =
    RECEIPT_MIME_ALIASES[normalizedMimeType] || normalizedMimeType;
  if (SUPPORTED_RECEIPT_MIME_TYPES.includes(canonicalMimeType)) {
    return canonicalMimeType;
  }

  const extension = getReceiptExtension(filename);
  return RECEIPT_EXTENSION_TO_MIME[extension] || null;
}

function isPdfReceiptMimeType(mimeType, filename = '') {
  return normalizeReceiptMimeType(mimeType, filename) === 'application/pdf';
}

function isImageReceiptMimeType(mimeType, filename = '') {
  const normalizedMimeType = normalizeReceiptMimeType(mimeType, filename);
  return normalizedMimeType?.startsWith('image/') || false;
}

function getReceiptUploadMessage(key, language = DEFAULT_LANGUAGE) {
  const languageCode = normalizeLanguageCode(language, DEFAULT_LANGUAGE);
  const translations = RECEIPT_UPLOAD_MESSAGES[key];
  if (!translations) {
    return '';
  }

  return translations[languageCode] || translations[DEFAULT_LANGUAGE];
}

module.exports = {
  MAX_RECEIPT_FILE_SIZE,
  SUPPORTED_RECEIPT_EXTENSIONS,
  SUPPORTED_RECEIPT_MIME_TYPES,
  getReceiptExtension,
  getReceiptUploadMessage,
  isImageReceiptMimeType,
  isPdfReceiptMimeType,
  normalizeReceiptMimeType,
};
