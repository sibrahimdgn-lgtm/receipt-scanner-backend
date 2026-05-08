const test = require('node:test');
const assert = require('node:assert/strict');

const { buildReceiptPrompt, buildReceiptSchema } = require('../src/services/geminiService');
const { normalizeLanguageCode } = require('../src/config/languages');

test('normalizes supported language codes', () => {
  assert.equal(normalizeLanguageCode('tr-TR'), 'tr');
  assert.equal(normalizeLanguageCode('en-US,en;q=0.9'), 'en');
  assert.equal(normalizeLanguageCode('de_DE'), 'de');
  assert.equal(normalizeLanguageCode('ar-SA'), 'ar');
  assert.equal(normalizeLanguageCode('fr'), 'tr');
});

test('builds English schema and prompt with English categories', () => {
  const schema = buildReceiptSchema('en');
  const categorySchema = schema.properties.line_items.items.properties.category;
  const transactionDateSchema =
    schema.properties.line_items.items.properties.transaction_date;
  const prompt = buildReceiptPrompt('en');

  assert.deepEqual(categorySchema.enum, [
    'Food',
    'Stationery',
    'Transport/Travel',
    'Electronics',
    'Health',
    'Entertainment',
    'Other',
  ]);
  assert.equal(transactionDateSchema.nullable, true);
  assert.match(prompt, /Translate item_name values and category labels into English/);
  assert.match(prompt, /transaction_date/);
  assert.match(prompt, /bank statement/i);
});

test('builds German schema and prompt with German categories', () => {
  const schema = buildReceiptSchema('de');
  const categorySchema = schema.properties.line_items.items.properties.category;
  const prompt = buildReceiptPrompt('de');

  assert.deepEqual(categorySchema.enum, [
    'Lebensmittel',
    'Schreibwaren',
    'Transport/Reise',
    'Elektronik',
    'Gesundheit',
    'Unterhaltung',
    'Sonstiges',
  ]);
  assert.match(prompt, /German \(Deutsch\)/);
});

test('builds Arabic schema and prompt with Arabic categories', () => {
  const schema = buildReceiptSchema('ar');
  const categorySchema = schema.properties.line_items.items.properties.category;
  const prompt = buildReceiptPrompt('ar');

  assert.deepEqual(categorySchema.enum, [
    'طعام',
    'قرطاسية',
    'مواصلات/سفر',
    'إلكترونيات',
    'صحة',
    'ترفيه',
    'أخرى',
  ]);
  assert.match(prompt, /Arabic \(العربية\)/);
});
