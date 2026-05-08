const test = require('node:test');
const assert = require('node:assert/strict');

const {
  getReceiptCategoryKey,
  getReceiptCategoryLabel,
  normalizeReceiptLineItems,
  resolveLineItemCategoryKey,
} = require('../src/config/receiptCategories');

test('maps common food categories into canonical food key', () => {
  assert.equal(getReceiptCategoryKey('Produce'), 'food');
  assert.equal(getReceiptCategoryKey('grocery'), 'food');
  assert.equal(getReceiptCategoryKey('Lebensmittel'), 'food');
  assert.equal(getReceiptCategoryKey('طعام'), 'food');
});

test('maps transportation keywords into canonical transport key', () => {
  assert.equal(resolveLineItemCategoryKey({ item_name: 'Diesel Fuel' }), 'transport');
  assert.equal(resolveLineItemCategoryKey({ category: 'Transport/Reise' }), 'transport');
});

test('falls back to canonical other key for unsupported categories', () => {
  assert.equal(getReceiptCategoryKey('Apparel'), 'other');
  assert.equal(resolveLineItemCategoryKey({ item_name: 'Unknown bundle' }), 'other');
});

test('normalizes all line items to canonical keys and can localize labels', () => {
  const items = normalizeReceiptLineItems([
    { item_name: 'USB-C Cable', category: 'Electronics' },
    { item_name: 'Defter', category: '' },
    { item_name: 'Movie Ticket', category: 'Cinema' },
  ]);

  assert.deepEqual(
    items.map((item) => item.category),
    ['electronics', 'stationery', 'entertainment']
  );

  assert.equal(getReceiptCategoryLabel('electronics', 'tr'), 'Elektronik');
  assert.equal(getReceiptCategoryLabel('electronics', 'en'), 'Electronics');
  assert.equal(getReceiptCategoryLabel('electronics', 'de'), 'Elektronik');
  assert.equal(getReceiptCategoryLabel('electronics', 'ar'), 'إلكترونيات');
});

test('normalizes line-item transaction dates with receipt-date fallback', () => {
  const items = normalizeReceiptLineItems(
    [
      { item_name: 'Wire Transfer', transaction_date: '2026-04-01' },
      { item_name: 'Service Fee', transactionDate: '2026-04-02' },
      { item_name: 'Monthly Charge', transaction_date: 'invalid-date' },
      { item_name: 'Unknown Entry' },
    ],
    'Bank Statement',
    { receiptDate: '2026-04-30' }
  );

  assert.deepEqual(
    items.map((item) => item.transaction_date),
    ['2026-04-01', '2026-04-02', '2026-04-30', '2026-04-30']
  );
});
