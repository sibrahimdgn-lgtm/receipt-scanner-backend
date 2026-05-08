const DEFAULT_SHOP_CURRENCY = 'TRY';

const FALLBACK_CURRENCY_CODES = [
  'AED', 'ARS', 'AUD', 'BAM', 'BBD', 'BDT', 'BGN', 'BHD', 'BMD', 'BND',
  'BOB', 'BRL', 'BSD', 'BWP', 'BYN', 'BZD', 'CAD', 'CHF', 'CLP', 'CNY',
  'COP', 'CRC', 'CZK', 'DKK', 'DOP', 'DZD', 'EGP', 'EUR', 'FJD', 'GBP',
  'GEL', 'GHS', 'GTQ', 'HKD', 'HNL', 'HRK', 'HUF', 'IDR', 'ILS', 'INR',
  'ISK', 'JMD', 'JOD', 'JPY', 'KES', 'KRW', 'KWD', 'KZT', 'LBP', 'LKR',
  'MAD', 'MDL', 'MKD', 'MUR', 'MXN', 'MYR', 'NGN', 'NIO', 'NOK', 'NPR',
  'NZD', 'OMR', 'PAB', 'PEN', 'PHP', 'PKR', 'PLN', 'PYG', 'QAR', 'RON',
  'RSD', 'RUB', 'SAR', 'SEK', 'SGD', 'THB', 'TND', 'TRY', 'TWD', 'UAH',
  'UGX', 'USD', 'UYU', 'UZS', 'VND', 'XOF', 'ZAR',
];

const ISO_CURRENCY_CODES = new Set(
  typeof Intl.supportedValuesOf === 'function'
    ? Intl.supportedValuesOf('currency').map((code) => code.toUpperCase())
    : FALLBACK_CURRENCY_CODES
);

const CURRENCY_CODE_ALIASES = {
  TL: 'TRY',
  YTL: 'TRY',
  TRYTL: 'TRY',
  TURKISHLIRA: 'TRY',
  TURKISHLIRASI: 'TRY',
  EURO: 'EUR',
  EUROS: 'EUR',
  RMB: 'CNY',
  YUAN: 'CNY',
  US$: 'USD',
  CAD$: 'CAD',
  AUD$: 'AUD',
  NZD$: 'NZD',
  SGD$: 'SGD',
  HKD$: 'HKD',
  TWD$: 'TWD',
  NTD: 'TWD',
};

const DEFAULT_SYMBOL_BY_CODE = {
  AED: 'AED',
  AUD: 'A$',
  BRL: 'R$',
  CAD: 'CA$',
  CHF: 'CHF',
  CNY: '¥',
  CZK: 'Kc',
  DKK: 'kr',
  EUR: '€',
  GBP: '£',
  HKD: 'HK$',
  HUF: 'Ft',
  IDR: 'Rp',
  INR: '₹',
  JPY: '¥',
  KRW: '₩',
  MXN: 'MX$',
  MYR: 'RM',
  NOK: 'kr',
  NZD: 'NZ$',
  PHP: '₱',
  PLN: 'zl',
  QAR: 'QAR',
  RON: 'lei',
  RUB: '₽',
  SAR: 'SAR',
  SEK: 'kr',
  SGD: 'S$',
  THB: '฿',
  TRY: '₺',
  TWD: 'NT$',
  UAH: '₴',
  USD: '$',
  VND: '₫',
  ZAR: 'R',
};

const SYMBOL_TO_CODES = new Map([
  ['₺', ['TRY']],
  ['€', ['EUR']],
  ['£', ['GBP']],
  ['₹', ['INR']],
  ['₩', ['KRW']],
  ['₽', ['RUB']],
  ['₴', ['UAH']],
  ['₦', ['NGN']],
  ['₱', ['PHP']],
  ['฿', ['THB']],
  ['₫', ['VND']],
  ['R$', ['BRL']],
  ['CA$', ['CAD']],
  ['A$', ['AUD']],
  ['NZ$', ['NZD']],
  ['S$', ['SGD']],
  ['HK$', ['HKD']],
  ['NT$', ['TWD']],
  ['MX$', ['MXN']],
  ['RM', ['MYR']],
  ['Rp', ['IDR']],
  ['CHF', ['CHF']],
  ['lei', ['RON']],
  ['Ft', ['HUF']],
  ['kr', ['DKK', 'ISK', 'NOK', 'SEK']],
  ['Kc', ['CZK']],
  ['¥', ['CNY', 'JPY']],
  ['$', ['AUD', 'BBD', 'BMD', 'BSD', 'BZD', 'CAD', 'CLP', 'COP', 'HKD', 'JMD', 'MXN', 'NZD', 'SGD', 'TWD', 'USD', 'UYU']],
  ['SAR', ['SAR']],
  ['AED', ['AED']],
  ['QAR', ['QAR']],
  ['R', ['ZAR']],
]);

function tokenizeCurrencyCandidate(value) {
  return value
    .toString()
    .trim()
    .toUpperCase()
    .split(/[^A-Z$]+/)
    .filter(Boolean);
}

function coerceCurrencyCode(value) {
  if (value == null) {
    return null;
  }

  const raw = value.toString().trim().toUpperCase();
  if (!raw) {
    return null;
  }

  if (ISO_CURRENCY_CODES.has(raw)) {
    return raw;
  }

  if (CURRENCY_CODE_ALIASES[raw]) {
    return CURRENCY_CODE_ALIASES[raw];
  }

  const compact = raw.replace(/[^A-Z$]/g, '');
  if (ISO_CURRENCY_CODES.has(compact)) {
    return compact;
  }

  if (CURRENCY_CODE_ALIASES[compact]) {
    return CURRENCY_CODE_ALIASES[compact];
  }

  for (const token of tokenizeCurrencyCandidate(raw)) {
    if (ISO_CURRENCY_CODES.has(token)) {
      return token;
    }
    if (CURRENCY_CODE_ALIASES[token]) {
      return CURRENCY_CODE_ALIASES[token];
    }
  }

  return null;
}

function normalizeCurrencyCode(value, fallback = DEFAULT_SHOP_CURRENCY) {
  return coerceCurrencyCode(value) || coerceCurrencyCode(fallback) || DEFAULT_SHOP_CURRENCY;
}

function normalizeCurrencySymbol(value) {
  if (value == null) {
    return null;
  }

  const normalized = value.toString().trim().replace(/\s+/g, ' ');
  return normalized || null;
}

function getCurrencyCodesForSymbol(symbol) {
  const normalized = normalizeCurrencySymbol(symbol);
  if (!normalized) {
    return [];
  }

  return SYMBOL_TO_CODES.get(normalized) || [];
}

function getCurrencySymbol(code, fallbackSymbol = null) {
  const normalizedCode = coerceCurrencyCode(code);
  if (fallbackSymbol) {
    return normalizeCurrencySymbol(fallbackSymbol);
  }
  if (!normalizedCode) {
    return null;
  }
  return DEFAULT_SYMBOL_BY_CODE[normalizedCode] || normalizedCode;
}

module.exports = {
  DEFAULT_SHOP_CURRENCY,
  coerceCurrencyCode,
  normalizeCurrencyCode,
  normalizeCurrencySymbol,
  getCurrencyCodesForSymbol,
  getCurrencySymbol,
};
