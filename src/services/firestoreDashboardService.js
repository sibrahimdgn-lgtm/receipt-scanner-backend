const {
  DEFAULT_SHOP_CURRENCY,
  getCurrencySymbol,
  normalizeCurrencyCode,
} = require('../config/currency');
const {
  DEFAULT_RECEIPT_CATEGORY_KEY,
  getReceiptCategoryKey,
  getReceiptCategoryLabel,
} = require('../config/receiptCategories');
const {
  DEFAULT_LANGUAGE,
  normalizeLanguageCode,
} = require('../config/languages');
const {
  buildTrendRowsWithDrilldown,
  getDashboardPeriodConfig,
  supportsTrendDrilldown,
} = require('./dashboardTrendService');

const DASHBOARD_HISTORY_LIMIT = 20;

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

function parseIsoDate(value) {
  if (typeof value !== 'string') {
    return null;
  }

  const trimmed = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) {
    return null;
  }

  const parsed = new Date(`${trimmed}T00:00:00.000Z`);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function formatIsoDate(value) {
  if (!(value instanceof Date) || Number.isNaN(value.getTime())) {
    return null;
  }

  return value.toISOString().slice(0, 10);
}

function startOfUtcDay(date) {
  return new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate())
  );
}

function startOfUtcWeek(date) {
  const day = date.getUTCDay() || 7;
  const start = startOfUtcDay(date);
  start.setUTCDate(start.getUTCDate() - (day - 1));
  return start;
}

function startOfUtcMonth(date) {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1));
}

function startOfUtcYear(date) {
  return new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
}

function shiftUtcDate(date, { days = 0, months = 0, years = 0 } = {}) {
  return new Date(
    Date.UTC(
      date.getUTCFullYear() + years,
      date.getUTCMonth() + months,
      date.getUTCDate() + days
    )
  );
}

function resolveClientLocalNow(
  now = new Date(),
  timezoneOffsetMinutes = null
) {
  const base = now instanceof Date ? now : new Date(now);
  if (Number.isNaN(base.getTime())) {
    return new Date();
  }

  if (!Number.isFinite(timezoneOffsetMinutes)) {
    return new Date(base.getTime());
  }

  // Flutter sends local-minus-UTC minutes; shifting the server clock by that
  // delta lets us derive the client's current calendar day safely.
  return new Date(base.getTime() + timezoneOffsetMinutes * 60000);
}

function getPeriodRange(
  period,
  now = new Date(),
  timezoneOffsetMinutes = null
) {
  const localNow = resolveClientLocalNow(now, timezoneOffsetMinutes);
  const today = startOfUtcDay(localNow);

  switch (period) {
    case 'weekly':
      return {
        start: shiftUtcDate(today, { months: -1 }),
        end: today,
      };
    case 'monthly':
      return {
        start: shiftUtcDate(today, { months: -6 }),
        end: today,
      };
    case 'yearly':
      return {
        start: shiftUtcDate(today, { years: -5 }),
        end: today,
      };
    case 'daily':
    default:
      return {
        start: today,
        end: today,
      };
  }
}

function bucketDateForTrunc(date, trunc) {
  switch (trunc) {
    case 'week':
      return startOfUtcWeek(date);
    case 'month':
      return startOfUtcMonth(date);
    case 'year':
      return startOfUtcYear(date);
    case 'day':
    default:
      return startOfUtcDay(date);
  }
}

function localizeLineItems(lineItems, language) {
  const languageCode = normalizeLanguageCode(language);
  if (!Array.isArray(lineItems)) {
    return [];
  }

  return lineItems.map((lineItem) => {
    const categoryKey = getReceiptCategoryKey(
      lineItem.category_key || lineItem.category || lineItem.item_name
    );

    return {
      ...lineItem,
      category_key: categoryKey,
      category: getReceiptCategoryLabel(categoryKey, languageCode),
    };
  });
}

function normalizeReceiptForHistory(receipt, language, shopCurrencyCode) {
  const currencyCode = normalizeCurrencyCode(
    receipt.currency_code || receipt.currency,
    shopCurrencyCode
  );

  return {
    ...receipt,
    currency: currencyCode,
    currency_code: currencyCode,
    currency_symbol:
      receipt.currency_symbol || getCurrencySymbol(currencyCode),
    item_count: Array.isArray(receipt.line_items)
      ? receipt.line_items.length
      : toNumber(receipt.item_count, 0),
    line_items: localizeLineItems(receipt.line_items, language),
  };
}

function buildAvailableCurrencies(receipts, fallbackCurrency) {
  const grouped = new Map();

  for (const receipt of receipts) {
    const code = normalizeCurrencyCode(receipt.currency_code, fallbackCurrency);
    const current = grouped.get(code) || {
      currency_code: code,
      currency_symbol: receipt.currency_symbol || getCurrencySymbol(code),
      receipt_count: 0,
      total_spend: 0,
    };

    current.receipt_count += 1;
    current.total_spend += toNumber(receipt.total_amount, 0);
    grouped.set(code, current);
  }

  return Array.from(grouped.values()).sort((left, right) => {
    if (right.receipt_count !== left.receipt_count) {
      return right.receipt_count - left.receipt_count;
    }
    return left.currency_code.localeCompare(right.currency_code);
  });
}

function buildCategorySummary(receipts, language) {
  const grouped = new Map();
  const languageCode = normalizeLanguageCode(language);

  for (const receipt of receipts) {
    for (const lineItem of receipt.line_items || []) {
      const categoryKey = getReceiptCategoryKey(
        lineItem.category_key || lineItem.category || lineItem.item_name,
        DEFAULT_RECEIPT_CATEGORY_KEY
      );
      const current = grouped.get(categoryKey) || {
        category_key: categoryKey,
        category: getReceiptCategoryLabel(categoryKey, languageCode),
        total: 0,
      };

      current.total += toNumber(lineItem.total_price, 0);
      grouped.set(categoryKey, current);
    }
  }

  return Array.from(grouped.values())
    .sort((left, right) => right.total - left.total)
    .slice(0, 6);
}

function buildVendorSummary(receipts) {
  const grouped = new Map();

  for (const receipt of receipts) {
    const vendor = receipt.vendor_name || 'Unknown';
    grouped.set(vendor, (grouped.get(vendor) || 0) + toNumber(receipt.total_amount, 0));
  }

  return Array.from(grouped.entries())
    .map(([vendor, total]) => ({ vendor, total }))
    .sort((left, right) => right.total - left.total)
    .slice(0, 6);
}

function buildTrendSummary(receipts, period, periodConfig) {
  const topLevel = new Map();
  const drilldown = new Map();
  const canDrilldown = supportsTrendDrilldown(period);

  for (const receipt of receipts) {
    const parsedDate = parseIsoDate(receipt.receipt_date);
    if (!parsedDate) {
      continue;
    }

    const parentDate = formatIsoDate(
      bucketDateForTrunc(parsedDate, periodConfig.trunc)
    );
    const total = toNumber(receipt.total_amount, 0);
    topLevel.set(parentDate, (topLevel.get(parentDate) || 0) + total);

    if (!canDrilldown) {
      continue;
    }

    const drilldownDate = formatIsoDate(
      bucketDateForTrunc(parsedDate, periodConfig.drilldownTrunc)
    );
    const mapKey = `${parentDate}:${drilldownDate}`;
    const existing = drilldown.get(mapKey) || {
      parent_date: parentDate,
      date: drilldownDate,
      label_date: receipt.receipt_date,
      total: 0,
    };

    existing.total += total;
    if (
      existing.label_date == null
      || existing.label_date.localeCompare(receipt.receipt_date) > 0
    ) {
      existing.label_date = receipt.receipt_date;
    }

    drilldown.set(mapKey, existing);
  }

  const trendRows = Array.from(topLevel.entries())
    .map(([date, total]) => ({ date, total }))
    .sort((left, right) => left.date.localeCompare(right.date));
  const drilldownRows = Array.from(drilldown.values()).sort((left, right) => {
    const parentCompare = left.parent_date.localeCompare(right.parent_date);
    if (parentCompare !== 0) {
      return parentCompare;
    }
    return left.date.localeCompare(right.date);
  });

  return buildTrendRowsWithDrilldown({
    trendRows,
    drilldownRows,
    supportsDrilldown: canDrilldown,
  });
}

function buildDashboardSummary({
  receipts = [],
  period = 'daily',
  requestedCurrency,
  shopCurrencyCode = DEFAULT_SHOP_CURRENCY,
  language = DEFAULT_LANGUAGE,
  now = new Date(),
  timezoneOffsetMinutes = null,
}) {
  const normalizedLanguage = normalizeLanguageCode(language);
  const periodConfig = getDashboardPeriodConfig(period);
  const periodRange = getPeriodRange(period, now, timezoneOffsetMinutes);

  const inPeriodReceipts = receipts.filter((receipt) => {
    const parsedDate = parseIsoDate(receipt.receipt_date);
    return (
      parsedDate
      && parsedDate >= periodRange.start
      && parsedDate <= periodRange.end
    );
  });

  const availableCurrencies = buildAvailableCurrencies(
    inPeriodReceipts,
    shopCurrencyCode
  );
  const activeCurrency = normalizeCurrencyCode(
    requestedCurrency,
    availableCurrencies[0]?.currency_code || shopCurrencyCode
  );
  const filteredReceipts = inPeriodReceipts.filter(
    (receipt) =>
      normalizeCurrencyCode(receipt.currency_code, shopCurrencyCode)
      === activeCurrency
  );

  return {
    currency: activeCurrency,
    activeCurrency,
    availableCurrencies,
    hasMixedCurrencies: availableCurrencies.length > 1,
    preferredLanguage: normalizedLanguage,
    shopCurrency: normalizeCurrencyCode(shopCurrencyCode),
    summary: {
      total_spend: filteredReceipts.reduce(
        (sum, receipt) => sum + toNumber(receipt.total_amount, 0),
        0
      ),
      receipt_count: filteredReceipts.length,
    },
    categories: buildCategorySummary(filteredReceipts, normalizedLanguage),
    vendors: buildVendorSummary(filteredReceipts),
    trend: buildTrendSummary(filteredReceipts, period, periodConfig),
    periodDetails: periodConfig,
  };
}

function buildDashboardHistory({
  receipts = [],
  page = 1,
  limit = DASHBOARD_HISTORY_LIMIT,
  language = DEFAULT_LANGUAGE,
  shopCurrencyCode = DEFAULT_SHOP_CURRENCY,
}) {
  const safePage = Math.max(1, toNumber(page, 1));
  const total = receipts.length;
  const pages = Math.max(1, Math.ceil(total / limit));
  const startIndex = (safePage - 1) * limit;
  const pageReceipts = receipts
    .slice(startIndex, startIndex + limit)
    .map((receipt) =>
      normalizeReceiptForHistory(receipt, language, shopCurrencyCode)
    );

  return {
    receipts: pageReceipts,
    preferredLanguage: normalizeLanguageCode(language),
    total,
    page: safePage,
    pages,
  };
}

module.exports = {
  DASHBOARD_HISTORY_LIMIT,
  buildDashboardHistory,
  buildDashboardSummary,
  getPeriodRange,
  localizeLineItems,
  normalizeReceiptForHistory,
  resolveClientLocalNow,
};
