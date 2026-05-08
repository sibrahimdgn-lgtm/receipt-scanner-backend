const {
  DEFAULT_SHOP_CURRENCY,
  coerceCurrencyCode,
  getCurrencyCodesForSymbol,
  getCurrencySymbol,
  normalizeCurrencyCode,
  normalizeCurrencySymbol,
} = require('../config/currency');

function resolveReceiptCurrency(receiptData, { shopCurrencyCode } = {}) {
  const fallbackCurrency = normalizeCurrencyCode(
    shopCurrencyCode,
    DEFAULT_SHOP_CURRENCY
  );
  const geminiCode = coerceCurrencyCode(receiptData.currency_code);
  const symbol = normalizeCurrencySymbol(
    receiptData.currency_symbol || receiptData.currency_marker
  );
  const symbolCandidates = getCurrencyCodesForSymbol(symbol);

  let currencyCode = geminiCode;
  let source = 'gemini_code';
  let confidence = 0.95;

  if (geminiCode && symbolCandidates.length === 1 && symbolCandidates[0] === geminiCode) {
    source = 'gemini_code_symbol_match';
    confidence = 0.99;
  } else if (
    geminiCode &&
    symbolCandidates.length === 1 &&
    symbolCandidates[0] !== geminiCode
  ) {
    currencyCode = symbolCandidates[0];
    source = symbolCandidates[0] === fallbackCurrency
      ? 'symbol_override_shop_match'
      : 'symbol_override';
    confidence = symbolCandidates[0] === fallbackCurrency ? 0.97 : 0.93;
  } else if (geminiCode && symbolCandidates.length > 1 && symbolCandidates.includes(geminiCode)) {
    source = 'gemini_code_ambiguous_symbol';
    confidence = 0.92;
  } else if (!geminiCode && symbolCandidates.length === 1) {
    currencyCode = symbolCandidates[0];
    source = 'symbol_inference';
    confidence = 0.86;
  } else if (!currencyCode) {
    currencyCode = fallbackCurrency;
    source = 'shop_default';
    confidence = 0.35;
  } else if (symbolCandidates.length > 0 && !symbolCandidates.includes(currencyCode)) {
    source = 'gemini_code_overrode_symbol';
    confidence = 0.72;
  }

  return {
    currency_code: currencyCode,
    currency_symbol: getCurrencySymbol(currencyCode, symbol),
    currency_source: source,
    currency_confidence: Number(confidence.toFixed(3)),
  };
}

module.exports = {
  resolveReceiptCurrency,
};
