const test = require('node:test');
const assert = require('node:assert/strict');

const {
  resolveReceiptCurrency,
} = require('../src/services/currencyDetectionService');

test('keeps Gemini code when ambiguous symbol still matches the code', () => {
  const resolved = resolveReceiptCurrency({
    currency_code: 'USD',
    currency_symbol: '$',
  });

  assert.equal(resolved.currency_code, 'USD');
  assert.equal(resolved.currency_source, 'gemini_code_ambiguous_symbol');
});

test('overrides conflicting Gemini code when the receipt symbol is unique', () => {
  const resolved = resolveReceiptCurrency(
    {
      currency_code: 'USD',
      currency_symbol: '₺',
    },
    {
      shopCurrencyCode: 'TRY',
    }
  );

  assert.equal(resolved.currency_code, 'TRY');
  assert.equal(resolved.currency_symbol, '₺');
  assert.equal(resolved.currency_source, 'symbol_override_shop_match');
});

test('infers currency from a unique symbol when Gemini omits the code', () => {
  const resolved = resolveReceiptCurrency({
    currency_symbol: '€',
  });

  assert.equal(resolved.currency_code, 'EUR');
  assert.equal(resolved.currency_source, 'symbol_inference');
});

test('falls back to the shop currency when no usable currency signal exists', () => {
  const resolved = resolveReceiptCurrency(
    {},
    {
      shopCurrencyCode: 'AED',
    }
  );

  assert.equal(resolved.currency_code, 'AED');
  assert.equal(resolved.currency_source, 'shop_default');
});
