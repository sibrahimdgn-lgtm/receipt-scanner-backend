/**
 * Auth Routes
 * POST /api/auth/register — bootstrap Firestore shop + user after Firebase Auth signup
 * POST /api/auth/login    — verify Firebase token and return tenant context
 */

const express = require('express');
const router = express.Router();

const {
  DEFAULT_SHOP_CURRENCY,
  normalizeCurrencyCode,
} = require('../config/currency');
const {
  DEFAULT_LANGUAGE,
  normalizeLanguageCode,
} = require('../config/languages');
const firebaseAuth = require('../middleware/firebaseAuth');
const { verifyFirebaseIdToken } = require('../middleware/firebaseAuth');
const {
  buildSuggestedShopName,
  createShopAndUserSession,
  getUserContext,
  hasCompleteSessionContext,
  syncUserProfileFromToken,
  updateUserPreferredLanguage,
} = require('../services/firestoreDataService');

router.post('/register', async (req, res, next) => {
  try {
    const { idToken, shop_name } = req.body;
    const decodedToken = await verifyFirebaseIdToken(idToken);
    const email = decodedToken.email || req.body.email || null;
    const shopCurrency = normalizeCurrencyCode(
      req.body.currency || req.body.shop_currency || DEFAULT_SHOP_CURRENCY
    );
    const preferredLanguage = normalizeLanguageCode(
      req.body.preferred_language
        || req.body.preferredLanguage
        || req.headers['x-user-language']
        || req.headers['accept-language'],
      DEFAULT_LANGUAGE
    );

    if (!shop_name || !shop_name.toString().trim()) {
      return res.status(400).json({ error: 'shop_name is required.' });
    }

    const context = await createShopAndUserSession({
      userId: decodedToken.uid,
      email,
      shopName: shop_name,
      shopCurrency,
      preferredLanguage,
    });

    if (!context?.shop || !context?.user) {
      throw new Error('Failed to create Firebase-backed session context.');
    }

    return res.status(201).json(
      buildSessionPayload({
        idToken,
        context,
        fallbackEmail: email,
      })
    );
  } catch (err) {
    next(err);
  }
});

router.post('/login', async (req, res, next) => {
  try {
    const { idToken } = req.body;
    const decodedToken = await verifyFirebaseIdToken(idToken);
    const preferredLanguage = normalizeLanguageCode(
      req.body.preferred_language
        || req.body.preferredLanguage
        || req.headers['x-user-language']
        || req.headers['accept-language'],
      DEFAULT_LANGUAGE
    );

    const context = await syncUserProfileFromToken({
      userId: decodedToken.uid,
      email: decodedToken.email || req.body.email || null,
      preferredLanguage,
    });

    if (!hasCompleteSessionContext(context)) {
      return res.status(404).json({
        code: 'account_setup_required',
        needsShopSetup: true,
        email: decodedToken.email || req.body.email || null,
        suggestedShopName: buildSuggestedShopName(
          decodedToken.email || req.body.email || null
        ),
        error:
          'Your Firebase account exists, but the Firestore shop profile is missing. Create a new shop to continue.',
      });
    }

    return res.json(
      buildSessionPayload({
        idToken,
        context,
        fallbackEmail: decodedToken.email || req.body.email || null,
      })
    );
  } catch (err) {
    next(err);
  }
});

router.post('/setup-shop', async (req, res, next) => {
  try {
    const { idToken, shop_name } = req.body;
    const decodedToken = await verifyFirebaseIdToken(idToken);
    const email = decodedToken.email || req.body.email || null;
    const shopCurrency = normalizeCurrencyCode(
      req.body.currency || req.body.shop_currency || DEFAULT_SHOP_CURRENCY
    );
    const preferredLanguage = normalizeLanguageCode(
      req.body.preferred_language
        || req.body.preferredLanguage
        || req.headers['x-user-language']
        || req.headers['accept-language'],
      DEFAULT_LANGUAGE
    );

    if (!shop_name || !shop_name.toString().trim()) {
      return res.status(400).json({ error: 'shop_name is required.' });
    }

    const context = await createShopAndUserSession({
      userId: decodedToken.uid,
      email,
      shopName: shop_name,
      shopCurrency,
      preferredLanguage,
    });

    if (!hasCompleteSessionContext(context)) {
      throw new Error('Failed to complete Firestore shop setup.');
    }

    return res.json(
      buildSessionPayload({
        idToken,
        context,
        fallbackEmail: email,
      })
    );
  } catch (err) {
    next(err);
  }
});

router.put('/preferences', firebaseAuth, async (req, res, next) => {
  try {
    const preferredLanguage = normalizeLanguageCode(
      req.body.preferred_language || req.body.preferredLanguage,
      DEFAULT_LANGUAGE
    );

    const updatedLanguage = await updateUserPreferredLanguage(
      req.userId,
      preferredLanguage
    );

    if (!updatedLanguage) {
      return res.status(404).json({ error: 'User not found.' });
    }

    return res.json({ preferredLanguage: updatedLanguage });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

function buildSessionPayload({ idToken, context, fallbackEmail = null }) {
  const user = context.user || {};
  const shop = context.shop || {};

  return {
    token: idToken,
    shopId: shop.shop_id || user.shop_id || null,
    email: user.email || fallbackEmail,
    shopName: shop.name || null,
    currency: normalizeCurrencyCode(
      shop.currency || DEFAULT_SHOP_CURRENCY
    ),
    preferredLanguage: normalizeLanguageCode(
      user.preferred_language,
      DEFAULT_LANGUAGE
    ),
    userId: user.user_id || null,
  };
}
