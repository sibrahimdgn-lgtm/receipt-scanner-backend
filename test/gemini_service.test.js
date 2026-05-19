const test = require('node:test');
const assert = require('node:assert/strict');

const {
  getQwenApiKey,
  getQwenBaseUrl,
  getQwenVisionModel,
  hasQwenApiKey,
} = require('../src/services/geminiService');

test('Qwen config helpers reflect the current API key', () => {
  const originalApiKey = process.env.QWEN_API_KEY;
  const originalCreativeApiKey = process.env.CREATIVE_QWEN_API_KEY;
  const originalDashscopeApiKey = process.env.DASHSCOPE_API_KEY;
  const originalBaseUrl = process.env.CREATIVE_QWEN_BASE_URL;
  const originalModel = process.env.CREATIVE_QWEN_VL_MODEL;

  process.env.QWEN_API_KEY = 'test-key';
  assert.equal(getQwenApiKey(), 'test-key');
  assert.equal(hasQwenApiKey(), true);

  delete process.env.QWEN_API_KEY;
  process.env.CREATIVE_QWEN_API_KEY = 'creative-key';
  assert.equal(getQwenApiKey(), 'creative-key');

  delete process.env.CREATIVE_QWEN_API_KEY;
  process.env.DASHSCOPE_API_KEY = 'dashscope-key';
  assert.equal(getQwenApiKey(), 'dashscope-key');

  delete process.env.DASHSCOPE_API_KEY;
  delete process.env.CREATIVE_QWEN_API_KEY;
  process.env.QWEN_API_KEY = '   ';
  assert.equal(getQwenApiKey(), null);
  assert.equal(hasQwenApiKey(), false);

  process.env.CREATIVE_QWEN_BASE_URL = 'https://example.invalid/compatible-mode/v1';
  process.env.CREATIVE_QWEN_VL_MODEL = 'qwen-test-vl';
  assert.equal(getQwenBaseUrl(), 'https://example.invalid/compatible-mode/v1');
  assert.equal(getQwenVisionModel(), 'qwen-test-vl');

  if (originalApiKey == null) {
    delete process.env.QWEN_API_KEY;
  } else {
    process.env.QWEN_API_KEY = originalApiKey;
  }

  if (originalCreativeApiKey == null) {
    delete process.env.CREATIVE_QWEN_API_KEY;
  } else {
    process.env.CREATIVE_QWEN_API_KEY = originalCreativeApiKey;
  }

  if (originalDashscopeApiKey == null) {
    delete process.env.DASHSCOPE_API_KEY;
  } else {
    process.env.DASHSCOPE_API_KEY = originalDashscopeApiKey;
  }

  if (originalBaseUrl == null) {
    delete process.env.CREATIVE_QWEN_BASE_URL;
  } else {
    process.env.CREATIVE_QWEN_BASE_URL = originalBaseUrl;
  }

  if (originalModel == null) {
    delete process.env.CREATIVE_QWEN_VL_MODEL;
  } else {
    process.env.CREATIVE_QWEN_VL_MODEL = originalModel;
  }
});
