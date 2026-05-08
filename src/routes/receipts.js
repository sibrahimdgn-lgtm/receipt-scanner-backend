/**
 * Receipt Routes
 * POST /api/receipts/scan — upload a receipt file for AI processing
 * Firebase ID token is optional: authenticated users get results saved; guests get AI result only.
 */

const express = require('express');
const router = express.Router();

const firebaseAuth = require('../middleware/firebaseAuth');
const { optionalFirebaseAuth } = require('../middleware/firebaseAuth');
const upload = require('../middleware/upload');
const {
  DEFAULT_SHOP_CURRENCY,
  getCurrencySymbol,
  normalizeCurrencyCode,
} = require('../config/currency');
const {
  getReceiptCategoryKey,
  localizeReceiptLineItems,
  normalizeReceiptLineItems,
} = require('../config/receiptCategories');
const {
  DEFAULT_LANGUAGE,
  normalizeLanguageCode,
} = require('../config/languages');
const { analyzeReceipt } = require('../services/geminiService');
const { resolveReceiptCurrency } = require('../services/currencyDetectionService');
const {
  getReceiptById,
  getUserContext,
  saveReceipt,
  updateReceipt,
  deleteReceipt,
} = require('../services/firestoreDataService');
const { getReceiptUploadMessage } = require('../config/receiptFiles');
const {
  deleteStoredReceipt,
  uploadReceiptBuffer,
} = require('../services/storageService');

router.post(
  '/scan',
  optionalFirebaseAuth,
  upload.single('receipt'),
  async (req, res, next) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          error: getReceiptUploadMessage(
            'missingFile',
            req.headers['x-user-language'] || req.headers['accept-language']
          ),
        });
      }

      const { buffer, mimetype, originalname } = req.file;
      const requestContext = await getRequestContext(req);
      const isGuest = !req.shopId;

      console.log(
        `[Receipt] ${isGuest ? 'Guest' : `Shop ${req.shopId}`} upload ` +
          `(${(buffer.length / 1024).toFixed(1)} KB, ${mimetype}, lang: ${requestContext.language})`
      );

      const receiptData = await analyzeReceipt(buffer, mimetype, {
        language: requestContext.language,
      });
      const resolvedCurrency = resolveReceiptCurrency(receiptData, {
        shopCurrencyCode: requestContext.shopCurrencyCode,
      });
      const normalizedStorageReceiptData = {
        ...receiptData,
        line_items: normalizeReceiptLineItems(
          receiptData.line_items,
          receiptData.vendor_name,
          {
            output: 'key',
            receiptDate: receiptData.receipt_date,
          }
        ),
        ...resolvedCurrency,
      };

      console.log(
        `[Receipt] Gemini extracted: ${receiptData.vendor_name}, ` +
          `${receiptData.line_items?.length || 0} item(s), total: ${receiptData.total_amount}, ` +
          `currency: ${resolvedCurrency.currency_code} (${resolvedCurrency.currency_source}), ` +
          `lang: ${requestContext.language}`
      );

      if (!isGuest) {
        let uploadedFile = null;
        try {
          uploadedFile = await uploadReceiptBuffer(buffer, {
            shopId: req.shopId,
            userId: req.userId,
            originalFilename: originalname,
            mimeType: mimetype,
          });

          const savedReceipt = await saveReceipt(
            req.shopId,
            req.userId,
            normalizedStorageReceiptData,
            {
              scannedImageUrl: uploadedFile.url,
              scannedImagePath: uploadedFile.path,
              originalFilename: originalname,
              mimeType: uploadedFile.mimeType,
            }
          );

          return res.status(201).json({
            message: 'Receipt scanned and saved successfully.',
            currency: resolvedCurrency.currency_code,
            preferredLanguage: requestContext.language,
            receipt: formatReceiptForResponse(
              savedReceipt,
              requestContext.language,
              requestContext.shopCurrencyCode
            ),
            saved: true,
          });
        } catch (error) {
          if (uploadedFile?.path) {
            await deleteStoredReceipt(uploadedFile.path).catch(() => {});
          }
          throw error;
        }
      }

      return res.status(200).json({
        message: 'Receipt scanned (sign up to save & track).',
        currency: resolvedCurrency.currency_code,
        preferredLanguage: requestContext.language,
        receipt: formatReceiptForResponse(
          {
            vendor_name: receiptData.vendor_name,
            receipt_date: receiptData.receipt_date,
            currency_code: resolvedCurrency.currency_code,
            currency_symbol: resolvedCurrency.currency_symbol,
            currency_source: resolvedCurrency.currency_source,
            currency_confidence: resolvedCurrency.currency_confidence,
            total_amount: receiptData.total_amount,
            tax_amount: receiptData.tax_amount,
            line_items: normalizedStorageReceiptData.line_items,
            scanned_image_url: null,
          },
          requestContext.language,
          requestContext.shopCurrencyCode
        ),
        saved: false,
      });
    } catch (err) {
      next(err);
    }
  }
);

router.post('/import', firebaseAuth, async (req, res, next) => {
  try {
    const { receiptData } = req.body;
    if (!receiptData) {
      return res.status(400).json({ error: 'Missing receiptData.' });
    }

    const requestContext = await getRequestContext(req, { requireShop: true });
    const normalizedReceiptData = {
      ...receiptData,
      line_items: normalizeReceiptLineItems(
        receiptData.line_items,
        receiptData.vendor_name,
        {
          output: 'key',
          receiptDate: receiptData.receipt_date,
        }
      ),
      ...resolveReceiptCurrency(receiptData, {
        shopCurrencyCode: requestContext.shopCurrencyCode,
      }),
    };

    const savedReceipt = await saveReceipt(
      req.shopId,
      req.userId,
      normalizedReceiptData,
      {
        scannedImageUrl: receiptData.scanned_image_url || null,
        scannedImagePath: receiptData.scanned_image_path || null,
        originalFilename: receiptData.original_filename || null,
        mimeType: receiptData.mime_type || null,
      }
    );

    return res.status(201).json({
      message: 'Receipt imported successfully.',
      currency: normalizeCurrencyCode(
        savedReceipt.currency_code || requestContext.shopCurrencyCode
      ),
      preferredLanguage: requestContext.language,
      receipt: formatReceiptForResponse(
        savedReceipt,
        requestContext.language,
        requestContext.shopCurrencyCode
      ),
      saved: true,
    });
  } catch (err) {
    next(err);
  }
});

router.put('/:id', firebaseAuth, async (req, res, next) => {
  try {
    const { id } = req.params;
    const requestContext = await getRequestContext(req, { requireShop: true });
    const {
      vendor_name,
      total_amount,
      tax_amount,
      line_items = [],
      receipt_date,
      currency_code,
      currency_symbol,
    } = req.body;

    const normalizedCurrencyCode = currency_code
      ? normalizeCurrencyCode(currency_code)
      : null;
    const normalizedCurrencySymbol = normalizedCurrencyCode
      ? getCurrencySymbol(normalizedCurrencyCode, currency_symbol)
      : currency_symbol || null;
    const hasManualCurrencyOverride =
      normalizedCurrencyCode !== null || normalizedCurrencySymbol !== null;

    const updatedReceipt = await updateReceipt(req.shopId, id, req.userId, {
      vendor_name,
      total_amount,
      tax_amount,
      line_items,
      receipt_date,
      ...(normalizedCurrencyCode
        ? { currency_code: normalizedCurrencyCode }
        : {}),
      ...(normalizedCurrencySymbol
        ? { currency_symbol: normalizedCurrencySymbol }
        : {}),
      ...(hasManualCurrencyOverride
        ? {
            currency_source: 'manual_override',
            currency_confidence: 1,
          }
        : {}),
    });

    if (!updatedReceipt) {
      return res.status(404).json({
        error: 'Receipt not found or access denied.',
      });
    }

    return res.status(200).json({
      message: 'Receipt updated successfully.',
      preferredLanguage: requestContext.language,
      receipt: formatReceiptForResponse(
        updatedReceipt,
        requestContext.language,
        requestContext.shopCurrencyCode
      ),
      line_items: localizeLineItemsForResponse(
        updatedReceipt.line_items,
        requestContext.language
      ),
    });
  } catch (err) {
    next(err);
  }
});

router.delete('/:id', firebaseAuth, async (req, res, next) => {
  try {
    await getRequestContext(req, { requireShop: true });
    const deletedReceipt = await deleteReceipt(req.shopId, req.params.id);

    if (!deletedReceipt) {
      return res.status(404).json({
        error: 'Receipt not found or access denied.',
      });
    }

    if (deletedReceipt.scanned_image_path) {
      await deleteStoredReceipt(deletedReceipt.scanned_image_path).catch(() => {});
    }

    return res.status(200).json({
      message: 'Receipt deleted successfully.',
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

async function getRequestContext(req, { requireShop = false } = {}) {
  const fallbackLanguage = normalizeLanguageCode(
    req.headers['x-user-language']
      || req.body?.preferred_language
      || req.body?.preferredLanguage
      || req.query?.lang
      || req.headers['accept-language'],
    DEFAULT_LANGUAGE
  );

  if (!req.userId) {
    return {
      language: fallbackLanguage,
      shopCurrencyCode: DEFAULT_SHOP_CURRENCY,
    };
  }

  const context = await getUserContext(req.userId);
  req.shopId = context?.shop?.shop_id || context?.user?.shop_id || null;

  if (requireShop && !req.shopId) {
    const error = new Error('User is not linked to a shop in Firestore.');
    error.statusCode = 403;
    throw error;
  }

  return {
    language: normalizeLanguageCode(
      context?.user?.preferred_language,
      fallbackLanguage
    ),
    shopCurrencyCode: normalizeCurrencyCode(
      context?.shop?.currency,
      DEFAULT_SHOP_CURRENCY
    ),
  };
}

function localizeLineItemsForResponse(lineItems, language) {
  return localizeReceiptLineItems(lineItems, language).map((item) => ({
    ...item,
    category_key: getReceiptCategoryKey(item.category_key || item.category),
  }));
}

function formatReceiptForResponse(receipt, language, fallbackCurrency) {
  const currencyCode = normalizeCurrencyCode(
    receipt.currency_code || receipt.currency,
    fallbackCurrency
  );
  const currencySymbol =
    receipt.currency_symbol || getCurrencySymbol(currencyCode);

  return {
    ...receipt,
    currency: currencyCode,
    currency_code: currencyCode,
    currency_symbol: currencySymbol,
    line_items: localizeLineItemsForResponse(receipt.line_items || [], language),
  };
}
