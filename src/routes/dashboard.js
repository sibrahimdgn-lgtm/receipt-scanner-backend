/**
 * Dashboard Routes
 * GET /api/dashboard/summary — period-based spend totals + category breakdown
 * GET /api/dashboard/history — paginated receipt list
 */

const express = require('express');

const router = express.Router();

const firebaseAuth = require('../middleware/firebaseAuth');
const {
  DEFAULT_SHOP_CURRENCY,
  normalizeCurrencyCode,
} = require('../config/currency');
const {
  DEFAULT_LANGUAGE,
  normalizeLanguageCode,
} = require('../config/languages');
const {
  buildDashboardHistory,
  buildDashboardSummary,
} = require('../services/firestoreDashboardService');
const {
  getUserContext,
  listReceiptsByShop,
} = require('../services/firestoreDataService');

router.use(firebaseAuth);

router.get('/summary', async (req, res, next) => {
  try {
    const requestContext = await getRequestContext(req);
    const receipts = await listReceiptsByShop(req.shopId);

    return res.json(
      buildDashboardSummary({
        receipts,
        period: req.query.period || 'daily',
        requestedCurrency: req.query.currency,
        shopCurrencyCode: requestContext.shopCurrencyCode,
        language: requestContext.language,
      })
    );
  } catch (err) {
    next(err);
  }
});

router.get('/history', async (req, res, next) => {
  try {
    const requestContext = await getRequestContext(req);
    const receipts = await listReceiptsByShop(req.shopId);
    const page = Math.max(1, Number.parseInt(req.query.page || '1', 10));

    return res.json(
      buildDashboardHistory({
        receipts,
        page,
        language: requestContext.language,
        shopCurrencyCode: requestContext.shopCurrencyCode,
      })
    );
  } catch (err) {
    next(err);
  }
});

module.exports = router;

async function getRequestContext(req) {
  const fallbackLanguage = normalizeLanguageCode(
    req.headers['x-user-language'] || req.headers['accept-language'],
    DEFAULT_LANGUAGE
  );

  const context = await getUserContext(req.userId);
  req.shopId = context?.shop?.shop_id || context?.user?.shop_id || null;

  if (!req.shopId) {
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
