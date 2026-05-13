const test = require('node:test');
const assert = require('node:assert/strict');

const {
  buildDashboardHistory,
  buildDashboardSummary,
  getPeriodRange,
} = require('../src/services/firestoreDashboardService');

test('monthly summary aggregates Firestore receipts and exposes weekly drilldown', () => {
  const receipts = [
    {
      receipt_id: 'r-1',
      receipt_date: '2026-04-02',
      vendor_name: 'LCW',
      currency_code: 'TRY',
      total_amount: 1300.98,
      line_items: [
        { item_name: 'Shopping', total_price: 1300.98, category: 'other' },
      ],
    },
    {
      receipt_id: 'r-2',
      receipt_date: '2026-04-26',
      vendor_name: 'Coffee',
      currency_code: 'TRY',
      total_amount: 245.75,
      line_items: [
        { item_name: 'Latte', total_price: 245.75, category: 'food' },
      ],
    },
  ];

  const summary = buildDashboardSummary({
    receipts,
    period: 'monthly',
    shopCurrencyCode: 'TRY',
    language: 'tr',
    now: new Date('2026-04-30T12:00:00.000Z'),
  });

  assert.equal(summary.activeCurrency, 'TRY');
  assert.equal(summary.summary.receipt_count, 2);
  assert.equal(summary.availableCurrencies[0].receipt_count, 2);
  assert.equal(summary.trend.length, 1);
  assert.equal(summary.trend[0].drilldown.length, 2);
  assert.equal(summary.categories[0].category, 'Diğer');
  assert.equal(summary.categories[1].category, 'Gıda');
});

test('history localizes line items and preserves receipt pagination fields', () => {
  const receipts = [
    {
      receipt_id: 'r-3',
      vendor_name: 'Market',
      receipt_date: '2026-04-30',
      currency_code: 'TRY',
      total_amount: 99.5,
      currency_symbol: '₺',
      created_at: '2026-04-30T10:00:00.000Z',
      line_items: [
        {
          line_item_id: 'li-1',
          item_name: 'Domates',
          transaction_date: '2026-04-30',
          quantity: 1,
          unit_price: 99.5,
          total_price: 99.5,
          category: 'food',
        },
      ],
    },
  ];

  const history = buildDashboardHistory({
    receipts,
    page: 1,
    language: 'de',
    shopCurrencyCode: 'TRY',
  });

  assert.equal(history.total, 1);
  assert.equal(history.page, 1);
  assert.equal(history.pages, 1);
  assert.equal(history.receipts[0].currency, 'TRY');
  assert.equal(history.receipts[0].item_count, 1);
  assert.equal(history.receipts[0].line_items[0].category_key, 'food');
  assert.equal(history.receipts[0].line_items[0].category, 'Lebensmittel');
});

test('daily summary respects the client local day and excludes future receipt dates', () => {
  const receipts = [
    {
      receipt_id: 'r-local-today',
      receipt_date: '2026-05-13',
      vendor_name: 'Bugun',
      currency_code: 'TRY',
      total_amount: 90,
      line_items: [],
    },
    {
      receipt_id: 'r-local-tomorrow',
      receipt_date: '2026-05-14',
      vendor_name: 'Yarin',
      currency_code: 'TRY',
      total_amount: 45,
      line_items: [],
    },
  ];

  const summary = buildDashboardSummary({
    receipts,
    period: 'daily',
    shopCurrencyCode: 'TRY',
    language: 'tr',
    now: new Date('2026-05-12T21:30:00.000Z'),
    timezoneOffsetMinutes: 180,
  });

  assert.equal(summary.summary.receipt_count, 1);
  assert.equal(summary.summary.total_spend, 90);
  assert.deepEqual(summary.trend.map((bucket) => bucket.date), ['2026-05-13']);
});

test('daily range uses the client local calendar day for west-of-UTC timezones', () => {
  const range = getPeriodRange(
    'daily',
    new Date('2026-05-13T02:00:00.000Z'),
    -420
  );

  assert.equal(range.start.toISOString(), '2026-05-06T00:00:00.000Z');
  assert.equal(range.end.toISOString(), '2026-05-12T00:00:00.000Z');
});
