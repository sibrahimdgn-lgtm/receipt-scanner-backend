const db = require('../config/db');
const {
  DEFAULT_SHOP_CURRENCY,
  getCurrencySymbol,
  normalizeCurrencyCode,
} = require('../config/currency');
const {
  DEFAULT_LANGUAGE,
  normalizeLanguageCode,
} = require('../config/languages');
const {
  normalizeReceiptLineItems,
} = require('../config/receiptCategories');

function toNumber(value, fallback = 0) {
  if (value == null || value === '') {
    return fallback;
  }

  if (typeof value === 'number') {
    return Number.isFinite(value) ? value : fallback;
  }

  const parsed = Number.parseFloat(value.toString());
  return Number.isFinite(parsed) ? parsed : fallback;
}

function normalizeIsoDate(value, fallback = null) {
  if (typeof value !== 'string') {
    return fallback;
  }

  const trimmed = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) {
    return fallback;
  }

  return trimmed;
}

function buildSuggestedShopName(email, fallback = 'Receipt Shop') {
  if (typeof email !== 'string' || !email.includes('@')) {
    return fallback;
  }

  const localPart = email.split('@').shift()?.trim();
  if (!localPart) {
    return fallback;
  }

  const cleaned = localPart
    .replace(/[._-]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  if (!cleaned) {
    return fallback;
  }

  return cleaned
    .split(' ')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ');
}

function timestampToMillis(value) {
  if (!value) {
    return 0;
  }

  if (typeof value.toDate === 'function') {
    return value.toDate().getTime();
  }

  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? 0 : parsed.getTime();
}

function buildReceiptLineItems(lineItems, vendorName, receiptDate, existingItems = []) {
  const normalizedLineItems = normalizeReceiptLineItems(
    lineItems,
    vendorName,
    {
      output: 'key',
      receiptDate,
    }
  );

  return normalizedLineItems.map((item, index) => ({
    line_item_id:
      item.line_item_id
      || item.lineItemId
      || existingItems[index]?.line_item_id
      || db.newId(),
    item_name: item.item_name || item.itemName || 'Unknown Item',
    transaction_date: item.transaction_date || null,
    quantity: toNumber(item.quantity, 1),
    unit_price: toNumber(item.unit_price ?? item.unitPrice, 0),
    total_price: toNumber(item.total_price ?? item.totalPrice, 0),
    category: item.category_key || item.category || null,
  }));
}

function hasCompleteSessionContext(context) {
  return Boolean(
    context?.user?.user_id
      && context?.user?.shop_id
      && context?.shop?.shop_id
  );
}

function buildReceiptRecord({
  receiptId,
  shopId,
  userId,
  receiptData,
  existing = null,
  fileMeta = {},
}) {
  const vendorName =
    receiptData.vendor_name
    || receiptData.vendorName
    || existing?.vendor_name
    || 'Unknown Vendor';
  const receiptDate = normalizeIsoDate(
    receiptData.receipt_date || receiptData.receiptDate,
    existing?.receipt_date || null
  );
  const currencyCode = normalizeCurrencyCode(
    receiptData.currency_code
      || receiptData.currency
      || existing?.currency_code
      || DEFAULT_SHOP_CURRENCY
  );
  const currencySymbol = getCurrencySymbol(
    currencyCode,
    receiptData.currency_symbol
      || receiptData.currencySymbol
      || existing?.currency_symbol
      || null
  );

  const lineItems = buildReceiptLineItems(
    receiptData.line_items || receiptData.lineItems || existing?.line_items || [],
    vendorName,
    receiptDate,
    existing?.line_items || []
  );

  return {
    receipt_id: receiptId,
    shop_id: shopId,
    user_id: existing?.user_id || userId,
    vendor_name: vendorName,
    receipt_date: receiptDate,
    scanned_image_url:
      fileMeta.scannedImageUrl
      || receiptData.scanned_image_url
      || existing?.scanned_image_url
      || null,
    scanned_image_path:
      fileMeta.scannedImagePath
      || receiptData.scanned_image_path
      || existing?.scanned_image_path
      || null,
    original_filename:
      fileMeta.originalFilename || existing?.original_filename || null,
    mime_type: fileMeta.mimeType || existing?.mime_type || null,
    currency_code: currencyCode,
    currency_symbol: currencySymbol,
    currency_source:
      receiptData.currency_source
      || receiptData.currencySource
      || existing?.currency_source
      || 'shop_default',
    currency_confidence: toNumber(
      receiptData.currency_confidence ?? receiptData.currencyConfidence,
      toNumber(existing?.currency_confidence, 0.35)
    ),
    total_amount: toNumber(
      receiptData.total_amount ?? receiptData.totalAmount,
      toNumber(existing?.total_amount, 0)
    ),
    tax_amount: toNumber(
      receiptData.tax_amount ?? receiptData.taxAmount,
      toNumber(existing?.tax_amount, 0)
    ),
    line_items: lineItems,
    item_count: lineItems.length,
  };
}

function serializeReceipt(record = {}) {
  return db.normalizeDocument(record);
}

async function getUserContext(userId) {
  if (!userId) {
    return null;
  }

  const userSnapshot = await db.usersCollection().doc(userId).get();
  if (!userSnapshot.exists) {
    return null;
  }

  const user = userSnapshot.data();
  const shopId = user.shop_id;
  const shopSnapshot = shopId
    ? await db.shopsCollection().doc(shopId).get()
    : null;

  return {
    user: db.normalizeDocument(user),
    shop: shopSnapshot?.exists
      ? db.normalizeDocument(shopSnapshot.data())
      : null,
  };
}

async function syncUserProfileFromToken({
  userId,
  email,
  preferredLanguage = DEFAULT_LANGUAGE,
}) {
  const userRef = db.usersCollection().doc(userId);
  const snapshot = await userRef.get();
  if (!snapshot.exists) {
    return null;
  }

  const updates = {};
  if (email && snapshot.data().email !== email) {
    updates.email = email;
  }

  const normalizedLanguage = normalizeLanguageCode(preferredLanguage);
  if (normalizedLanguage && snapshot.data().preferred_language !== normalizedLanguage) {
    updates.preferred_language = normalizedLanguage;
  }

  if (Object.keys(updates).length > 0) {
    updates.updated_at = db.serverTimestamp();
    await userRef.set(updates, { merge: true });
  }

  return getUserContext(userId);
}

async function createShopAndUserSession({
  userId,
  email,
  shopName,
  shopCurrency = DEFAULT_SHOP_CURRENCY,
  preferredLanguage = DEFAULT_LANGUAGE,
}) {
  const existingContext = await getUserContext(userId);
  if (hasCompleteSessionContext(existingContext)) {
    await syncUserProfileFromToken({
      userId,
      email,
      preferredLanguage,
    });
    return getUserContext(userId);
  }

  const userRef = db.usersCollection().doc(userId);
  const normalizedLanguage = normalizeLanguageCode(preferredLanguage);
  const normalizedCurrency = normalizeCurrencyCode(shopCurrency);
  const normalizedShopName =
    (shopName || '').toString().trim() || buildSuggestedShopName(email);

  await db.firestore().runTransaction(async (transaction) => {
    const userSnapshot = await transaction.get(userRef);
    const existingUser = userSnapshot.exists ? userSnapshot.data() : null;

    let shopId = existingUser?.shop_id || existingContext?.shop?.shop_id || null;
    let shopRef = shopId
      ? db.shopsCollection().doc(shopId)
      : db.shopsCollection().doc();

    if (!shopId) {
      shopId = shopRef.id;
    }

    const shopSnapshot = await transaction.get(shopRef);
    const existingShop = shopSnapshot.exists ? shopSnapshot.data() : null;

    transaction.set(shopRef, {
      shop_id: shopId,
      name: existingShop?.name || normalizedShopName,
      email: email || existingShop?.email || null,
      currency: existingShop?.currency || normalizedCurrency,
      owner_user_id: userId,
      created_at: existingShop?.created_at || db.serverTimestamp(),
      updated_at: db.serverTimestamp(),
    }, { merge: true });

    transaction.set(userRef, {
      user_id: userId,
      shop_id: shopId,
      email: email || existingUser?.email || null,
      preferred_language:
        existingUser?.preferred_language || normalizedLanguage,
      created_at: existingUser?.created_at || db.serverTimestamp(),
      updated_at: db.serverTimestamp(),
    }, { merge: true });
  });

  return getUserContext(userId);
}

async function updateUserPreferredLanguage(userId, preferredLanguage) {
  const userRef = db.usersCollection().doc(userId);
  const snapshot = await userRef.get();
  if (!snapshot.exists) {
    return null;
  }

  const normalizedLanguage = normalizeLanguageCode(preferredLanguage);
  await userRef.set(
    {
      preferred_language: normalizedLanguage,
      updated_at: db.serverTimestamp(),
    },
    { merge: true }
  );

  return normalizedLanguage;
}

async function saveReceipt(shopId, userId, receiptData, fileMeta = {}) {
  const receiptRef = db.receiptsCollection().doc();
  const record = buildReceiptRecord({
    receiptId: receiptRef.id,
    shopId,
    userId,
    receiptData,
    fileMeta,
  });

  await receiptRef.set({
    ...record,
    created_at: db.serverTimestamp(),
    updated_at: db.serverTimestamp(),
  });

  return getReceiptById(shopId, receiptRef.id);
}

async function getReceiptById(shopId, receiptId, { raw = false } = {}) {
  const snapshot = await db.receiptsCollection().doc(receiptId).get();
  if (!snapshot.exists) {
    return null;
  }

  const record = snapshot.data();
  if (record.shop_id !== shopId) {
    return null;
  }

  return raw ? record : serializeReceipt(record);
}

async function listReceiptsByShop(shopId) {
  const snapshot = await db
    .receiptsCollection()
    .where('shop_id', '==', shopId)
    .get();

  return snapshot.docs
    .map((docSnapshot) => serializeReceipt(docSnapshot.data()))
    .sort(
      (a, b) =>
        timestampToMillis(b.created_at || b.updated_at)
        - timestampToMillis(a.created_at || a.updated_at)
    );
}

async function updateReceipt(shopId, receiptId, userId, receiptData) {
  const receiptRef = db.receiptsCollection().doc(receiptId);
  const snapshot = await receiptRef.get();
  if (!snapshot.exists) {
    return null;
  }

  const existing = snapshot.data();
  if (existing.shop_id !== shopId) {
    return null;
  }

  const record = buildReceiptRecord({
    receiptId,
    shopId,
    userId,
    receiptData,
    existing,
  });

  await receiptRef.set({
    ...record,
    created_at: existing.created_at || db.serverTimestamp(),
    updated_at: db.serverTimestamp(),
  });

  return getReceiptById(shopId, receiptId);
}

async function deleteReceipt(shopId, receiptId) {
  const receiptRef = db.receiptsCollection().doc(receiptId);
  const snapshot = await receiptRef.get();
  if (!snapshot.exists) {
    return null;
  }

  const record = snapshot.data();
  if (record.shop_id !== shopId) {
    return null;
  }

  await receiptRef.delete();
  return serializeReceipt(record);
}

module.exports = {
  buildSuggestedShopName,
  buildReceiptRecord,
  createShopAndUserSession,
  deleteReceipt,
  getUserContext,
  getReceiptById,
  hasCompleteSessionContext,
  listReceiptsByShop,
  saveReceipt,
  serializeReceipt,
  syncUserProfileFromToken,
  updateReceipt,
  updateUserPreferredLanguage,
};
