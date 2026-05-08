const test = require('node:test');
const assert = require('node:assert/strict');

const {
  buildSuggestedShopName,
  hasCompleteSessionContext,
} = require('../src/services/firestoreDataService');

test('buildSuggestedShopName derives a readable default from email', () => {
  assert.equal(
    buildSuggestedShopName('dogansibrahim@gmail.com'),
    'Dogansibrahim'
  );
  assert.equal(
    buildSuggestedShopName('my_shop-owner@example.com'),
    'My Shop Owner'
  );
});

test('hasCompleteSessionContext only returns true for linked user + shop pairs', () => {
  assert.equal(
    hasCompleteSessionContext({
      user: { user_id: 'u-1', shop_id: 's-1' },
      shop: { shop_id: 's-1' },
    }),
    true
  );
  assert.equal(
    hasCompleteSessionContext({
      user: { user_id: 'u-1', shop_id: 's-1' },
      shop: null,
    }),
    false
  );
  assert.equal(
    hasCompleteSessionContext({
      user: null,
      shop: { shop_id: 's-1' },
    }),
    false
  );
});
