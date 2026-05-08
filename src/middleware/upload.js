/**
 * Multer configuration for receipt file uploads.
 * Uses memory storage so the buffer can be sent directly to Gemini.
 */

const multer = require('multer');
const {
  MAX_RECEIPT_FILE_SIZE,
  getReceiptUploadMessage,
  normalizeReceiptMimeType,
} = require('../config/receiptFiles');

const storage = multer.memoryStorage();

const upload = multer({
  storage,
  limits: {
    fileSize: MAX_RECEIPT_FILE_SIZE,
  },
  fileFilter: (req, file, cb) => {
    const normalizedMimeType = normalizeReceiptMimeType(
      file.mimetype,
      file.originalname
    );

    if (normalizedMimeType) {
      file.mimetype = normalizedMimeType;
      cb(null, true);
    } else {
      const language =
        req.headers['x-user-language'] || req.headers['accept-language'];
      const error = new Error(
        getReceiptUploadMessage('unsupportedFileType', language)
      );
      error.code = 'UNSUPPORTED_RECEIPT_FILE';
      cb(error, false);
    }
  },
});

module.exports = upload;
