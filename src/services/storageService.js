const crypto = require('crypto');
const fs = require('fs/promises');
const path = require('path');

const { getStorageBucket } = require('../config/firebaseAdmin');
const { normalizeReceiptMimeType } = require('../config/receiptFiles');
const {
  buildLocalStoredPath,
  buildLocalUploadUrl,
  ensureUploadsDir,
  extractLocalUploadPath,
  isLocalStoredPath,
  normalizeRelativeUploadPath,
  resolveLocalUploadAbsolutePath,
} = require('../config/runtimePaths');

function sanitizeFilename(filename = 'receipt') {
  const basename = path.basename(filename).replace(/[^\w.-]+/g, '-');
  return basename || 'receipt';
}

function buildPublicDownloadUrl(bucketName, filePath, downloadToken) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(
    filePath
  )}?alt=media&token=${downloadToken}`;
}

async function uploadReceiptBuffer(
  fileBuffer,
  {
    shopId,
    userId,
    originalFilename = 'receipt',
    mimeType,
  }
) {
  const normalizedMimeType = normalizeReceiptMimeType(mimeType, originalFilename);
  const safeFilename = sanitizeFilename(originalFilename);
  const filePath =
    `shops/${shopId}/receipts/${Date.now()}-${userId || 'guest'}-${safeFilename}`;

  try {
    const bucket = getStorageBucket();
    const downloadToken = crypto.randomUUID();
    const file = bucket.file(filePath);

    await file.save(fileBuffer, {
      resumable: false,
      contentType: normalizedMimeType,
      metadata: {
        contentType: normalizedMimeType,
        metadata: {
          firebaseStorageDownloadTokens: downloadToken,
        },
      },
    });

    return {
      path: filePath,
      url: buildPublicDownloadUrl(bucket.name, filePath, downloadToken),
      mimeType: normalizedMimeType,
      storageProvider: 'firebase',
    };
  } catch (error) {
    console.warn(
      `[Storage] Firebase upload failed for ${filePath}. Falling back to local uploads.`,
      error
    );

    return saveReceiptLocally(fileBuffer, {
      relativePath: filePath,
      mimeType: normalizedMimeType,
    });
  }
}

async function deleteStoredReceipt(filePath) {
  if (!filePath) {
    return;
  }

  if (isLocalStoredPath(filePath)) {
    const localPath = extractLocalUploadPath(filePath);
    if (!localPath) {
      return;
    }

    await fs.rm(resolveLocalUploadAbsolutePath(localPath), {
      force: true,
    });
    return;
  }

  const bucket = getStorageBucket();
  await bucket.file(filePath).delete({ ignoreNotFound: true });
}

module.exports = {
  deleteStoredReceipt,
  uploadReceiptBuffer,
};

async function saveReceiptLocally(
  fileBuffer,
  { relativePath, mimeType }
) {
  ensureUploadsDir();
  const normalizedPath = normalizeRelativeUploadPath(relativePath);
  const absolutePath = resolveLocalUploadAbsolutePath(normalizedPath);

  await fs.mkdir(path.dirname(absolutePath), { recursive: true });
  await fs.writeFile(absolutePath, fileBuffer);

  return {
    path: buildLocalStoredPath(normalizedPath),
    url: buildLocalUploadUrl(normalizedPath),
    mimeType,
    storageProvider: 'local',
  };
}
