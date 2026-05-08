const { DEFAULT_LANGUAGE, normalizeLanguageCode } = require('./languages');

const CATEGORY_DEFINITIONS = [
  {
    key: 'food',
    labels: {
      tr: 'Gıda',
      en: 'Food',
      de: 'Lebensmittel',
      ar: 'طعام',
    },
    keywords: [
      'gida', 'grocery', 'food', 'market', 'supermarket', 'bakkal', 'manav',
      'restaurant', 'restoran', 'cafe', 'kahve', 'coffee', 'ekmek', 'sut',
      'milk', 'yogurt', 'yogurt', 'peynir', 'domates', 'meyve', 'sebze',
      'fruit', 'vegetable', 'water', 'su', 'cola', 'cikolata', 'cikolata',
      'snack', 'icecek', 'bakery', 'kasap', 'produce', 'طعام',
    ],
  },
  {
    key: 'stationery',
    labels: {
      tr: 'Kırtasiye',
      en: 'Stationery',
      de: 'Schreibwaren',
      ar: 'قرطاسية',
    },
    keywords: [
      'kirtasiye', 'stationery', 'office', 'school', 'okul', 'notebook',
      'defter', 'kalem', 'pencil', 'paper', 'printer', 'kitap', 'book',
      'marker', 'eraser', 'silgi', 'dosya', 'قرطاسية',
    ],
  },
  {
    key: 'transport',
    labels: {
      tr: 'Ulaşım/Yol',
      en: 'Transport/Travel',
      de: 'Transport/Reise',
      ar: 'مواصلات/سفر',
    },
    keywords: [
      'ulasim', 'ulasim yol', 'yol', 'transport', 'transportation', 'travel',
      'transit', 'taxi', 'taksi', 'metro', 'bus', 'otobus', 'parking', 'park',
      'fuel', 'petrol', 'diesel', 'benzin', 'toll', 'hgs', 'ogs', 'train',
      'tram', 'ferry', 'uber', 'مواصلات', 'سفر',
    ],
  },
  {
    key: 'electronics',
    labels: {
      tr: 'Elektronik',
      en: 'Electronics',
      de: 'Elektronik',
      ar: 'إلكترونيات',
    },
    keywords: [
      'elektronik', 'electronic', 'electronics', 'tech', 'teknoloji', 'kablo',
      'cable', 'charger', 'sarj', 'usb', 'kulaklik', 'earphone', 'headphone',
      'phone', 'telefon', 'laptop', 'tablet', 'monitor', 'keyboard', 'mouse',
      'adaptor', 'adapter', 'إلكترونيات',
    ],
  },
  {
    key: 'health',
    labels: {
      tr: 'Sağlık',
      en: 'Health',
      de: 'Gesundheit',
      ar: 'صحة',
    },
    keywords: [
      'saglik', 'eczane', 'pharmacy', 'medicine', 'medicin', 'medical',
      'medikal', 'vitamin', 'supplement', 'tablet', 'serum', 'hastane',
      'hospital', 'clinic', 'klinik', 'صحة',
    ],
  },
  {
    key: 'entertainment',
    labels: {
      tr: 'Eğlence',
      en: 'Entertainment',
      de: 'Unterhaltung',
      ar: 'ترفيه',
    },
    keywords: [
      'eglence', 'entertainment', 'cinema', 'sinema', 'movie', 'concert',
      'konser', 'game', 'oyun', 'netflix', 'spotify', 'toy', 'oyuncak',
      'streaming', 'playstation', 'xbox', 'ترفيه',
    ],
  },
  {
    key: 'other',
    labels: {
      tr: 'Diğer',
      en: 'Other',
      de: 'Sonstiges',
      ar: 'أخرى',
    },
    keywords: [
      'other', 'diger', 'shopping', 'apparel', 'fashion', 'clothing', 'giyim',
      'tekstil', 'أخرى',
    ],
  },
];

const CATEGORY_BY_KEY = Object.fromEntries(
  CATEGORY_DEFINITIONS.map((definition) => [definition.key, definition])
);

const DEFAULT_RECEIPT_CATEGORY_KEY = 'other';
const DEFAULT_RECEIPT_CATEGORY = CATEGORY_BY_KEY[DEFAULT_RECEIPT_CATEGORY_KEY].labels.tr;
const RECEIPT_CATEGORIES = CATEGORY_DEFINITIONS.map(
  (definition) => definition.labels.tr
);

function normalizeCategoryToken(value) {
  return value
    .toString()
    .trim()
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^\p{L}\p{N}/ ]+/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function getReceiptCategoryKey(value, fallback = DEFAULT_RECEIPT_CATEGORY_KEY) {
  if (value == null) {
    return fallback;
  }

  const raw = value.toString().trim();
  if (!raw) {
    return fallback;
  }

  if (CATEGORY_BY_KEY[raw]) {
    return raw;
  }

  const normalizedValue = normalizeCategoryToken(raw);

  for (const definition of CATEGORY_DEFINITIONS) {
    if (definition.key === normalizedValue) {
      return definition.key;
    }

    for (const label of Object.values(definition.labels)) {
      if (normalizeCategoryToken(label) === normalizedValue) {
        return definition.key;
      }
    }

    if (definition.keywords.some((keyword) => normalizedValue.includes(keyword))) {
      return definition.key;
    }
  }

  return fallback;
}

function getReceiptCategoryLabel(value, language = DEFAULT_LANGUAGE) {
  const languageCode = normalizeLanguageCode(language);
  const key = getReceiptCategoryKey(value);
  return CATEGORY_BY_KEY[key]?.labels[languageCode]
    || CATEGORY_BY_KEY[key]?.labels[DEFAULT_LANGUAGE]
    || CATEGORY_BY_KEY[DEFAULT_RECEIPT_CATEGORY_KEY].labels[DEFAULT_LANGUAGE];
}

function getReceiptCategoryLabels(language = DEFAULT_LANGUAGE) {
  const languageCode = normalizeLanguageCode(language);
  return CATEGORY_DEFINITIONS.map(
    (definition) => definition.labels[languageCode] || definition.labels[DEFAULT_LANGUAGE]
  );
}

function normalizeReceiptCategory(value, language = DEFAULT_LANGUAGE) {
  return getReceiptCategoryLabel(value, language);
}

function resolveLineItemCategoryKey(item = {}, fallback = DEFAULT_RECEIPT_CATEGORY_KEY) {
  const candidates = [
    item.category_key,
    item.categoryKey,
    item.category,
    item.item_name,
    item.itemName,
    item.vendor_name,
    item.vendorName,
  ];

  for (const candidate of candidates) {
    const key = getReceiptCategoryKey(candidate, '');
    if (key) {
      return key;
    }
  }

  return fallback;
}

function resolveLineItemCategory(item = {}, language = DEFAULT_LANGUAGE) {
  return getReceiptCategoryLabel(resolveLineItemCategoryKey(item), language);
}

function isValidIsoDate(value) {
  if (typeof value !== 'string') {
    return false;
  }

  const trimmed = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) {
    return false;
  }

  const parsed = new Date(`${trimmed}T00:00:00.000Z`);
  return !Number.isNaN(parsed.getTime())
    && parsed.toISOString().slice(0, 10) === trimmed;
}

function resolveLineItemTransactionDate(item = {}, receiptDate = null) {
  const candidates = [
    item.transaction_date,
    item.transactionDate,
  ];

  for (const candidate of candidates) {
    if (isValidIsoDate(candidate)) {
      return candidate.trim();
    }
  }

  if (isValidIsoDate(receiptDate)) {
    return receiptDate.trim();
  }

  return null;
}

function normalizeReceiptLineItems(
  lineItems,
  vendorName = null,
  { language = DEFAULT_LANGUAGE, output = 'key', receiptDate = null } = {}
) {
  if (!Array.isArray(lineItems)) {
    return [];
  }

  const languageCode = normalizeLanguageCode(language);

  return lineItems.map((item) => {
    const categoryKey = resolveLineItemCategoryKey(
      {
        ...item,
        vendor_name: vendorName,
      },
      DEFAULT_RECEIPT_CATEGORY_KEY
    );

    return {
      ...item,
      transaction_date: resolveLineItemTransactionDate(item, receiptDate),
      category_key: categoryKey,
      category: output === 'label'
        ? getReceiptCategoryLabel(categoryKey, languageCode)
        : categoryKey,
    };
  });
}

function localizeReceiptLineItems(lineItems, language = DEFAULT_LANGUAGE) {
  return normalizeReceiptLineItems(lineItems, null, {
    language,
    output: 'label',
  });
}

module.exports = {
  CATEGORY_DEFINITIONS,
  DEFAULT_RECEIPT_CATEGORY,
  DEFAULT_RECEIPT_CATEGORY_KEY,
  RECEIPT_CATEGORIES,
  getReceiptCategoryKey,
  getReceiptCategoryLabel,
  getReceiptCategoryLabels,
  localizeReceiptLineItems,
  normalizeReceiptCategory,
  normalizeReceiptLineItems,
  resolveLineItemCategory,
  resolveLineItemCategoryKey,
  resolveLineItemTransactionDate,
};
