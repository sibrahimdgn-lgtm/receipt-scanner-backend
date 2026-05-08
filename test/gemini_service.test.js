const test = require('node:test');
const assert = require('node:assert/strict');

const {
  getGeminiApiKey,
  hasGeminiApiKey,
} = require('../src/services/geminiService');

test('Gemini config helpers reflect the current API key', () => {
  const originalApiKey = process.env.GEMINI_API_KEY;

  process.env.GEMINI_API_KEY = 'test-key';
  assert.equal(getGeminiApiKey(), 'test-key');
  assert.equal(hasGeminiApiKey(), true);

  process.env.GEMINI_API_KEY = '   ';
  assert.equal(getGeminiApiKey(), null);
  assert.equal(hasGeminiApiKey(), false);

  if (originalApiKey == null) {
    delete process.env.GEMINI_API_KEY;
  } else {
    process.env.GEMINI_API_KEY = originalApiKey;
  }
});
