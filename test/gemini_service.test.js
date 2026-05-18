const test = require('node:test');
const assert = require('node:assert/strict');

const {
  getQwenApiKey,
  hasQwenApiKey,
} = require('../src/services/geminiService');

test('Qwen config helpers reflect the current API key', () => {
  const originalApiKey = process.env.QWEN_API_KEY;

  process.env.QWEN_API_KEY = 'test-key';
  assert.equal(getQwenApiKey(), 'test-key');
  assert.equal(hasQwenApiKey(), true);

  process.env.QWEN_API_KEY = '   ';
  assert.equal(getQwenApiKey(), null);
  assert.equal(hasQwenApiKey(), false);

  if (originalApiKey == null) {
    delete process.env.QWEN_API_KEY;
  } else {
    process.env.QWEN_API_KEY = originalApiKey;
  }
});
