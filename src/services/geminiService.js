/**
 * Qwen Vision Service
 * Sends receipt images or PDFs to Alibaba Qwen for structured data extraction.
 */

const {
  DEFAULT_RECEIPT_CATEGORY_KEY,
  getReceiptCategoryLabel,
  getReceiptCategoryLabels,
} = require('../config/receiptCategories');
const {
  DEFAULT_LANGUAGE,
  LANGUAGE_METADATA,
  normalizeLanguageCode,
} = require('../config/languages');
const { normalizeReceiptMimeType } = require('../config/receiptFiles');

const QWEN_RECEIPT_ENDPOINT =
  'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions';
const QWEN_RECEIPT_MODEL = 'qwen-vl-plus';

function getQwenApiKey() {
  return process.env.QWEN_API_KEY?.trim() || null;
}

function hasQwenApiKey() {
  return Boolean(getQwenApiKey());
}

function buildReceiptSchema(language = DEFAULT_LANGUAGE) {
  const languageCode = normalizeLanguageCode(language);
  const localizedCategories = getReceiptCategoryLabels(languageCode);

  return {
    type: 'object',
    properties: {
      vendor_name: {
        type: 'string',
        description: 'Name of the shop or vendor on the receipt',
      },
      receipt_date: {
        type: 'string',
        description: 'Date on the receipt in YYYY-MM-DD format',
      },
      currency_code: {
        type: 'string',
        description:
          'ISO 4217 currency code used for the paid amounts on the receipt, such as TRY, USD, EUR, CHF, AED or JPY. If the symbol is ambiguous, infer it from printed codes, receipt language, merchant country and tax cues. Never default to USD unless the receipt explicitly supports it.',
      },
      currency_symbol: {
        type: 'string',
        description:
          'The currency symbol or printed money marker shown near amounts, such as ₺, $, €, £, CHF, AED or kr.',
      },
      total_amount: {
        type: 'number',
        description: 'Total amount on the receipt',
      },
      tax_amount: {
        type: 'number',
        description: 'Tax amount on the receipt',
      },
      line_items: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            item_name: { type: 'string' },
            transaction_date: {
              type: 'string',
              nullable: true,
              description:
                'Line-level transaction date in YYYY-MM-DD format. Use the row-specific date when present; otherwise use the main receipt_date or null.',
            },
            quantity: { type: 'number' },
            unit_price: { type: 'number' },
            total_price: { type: 'number' },
            category: {
              type: 'string',
              description:
                `Choose only one of these ${LANGUAGE_METADATA[languageCode].promptName} categories: ${localizedCategories.join(', ')}.`,
              enum: localizedCategories,
            },
          },
          required: [
            'item_name',
            'transaction_date',
            'quantity',
            'unit_price',
            'total_price',
            'category',
          ],
        },
      },
    },
    required: [
      'vendor_name',
      'receipt_date',
      'currency_code',
      'currency_symbol',
      'total_amount',
      'tax_amount',
      'line_items',
    ],
  };
}

function buildReceiptPrompt(language = DEFAULT_LANGUAGE) {
  const languageCode = normalizeLanguageCode(language);
  const localizedCategories = getReceiptCategoryLabels(languageCode);
  const fallbackCategory = getReceiptCategoryLabel(
    DEFAULT_RECEIPT_CATEGORY_KEY,
    languageCode
  );
  const outputLanguage = LANGUAGE_METADATA[languageCode].promptName;

  return [
    'Analyze the provided receipt, invoice, image, or PDF file and return pure JSON only.',
    'Do not return markdown, explanations, comments, or code fences.',
    'Use exactly these JSON keys: vendor_name, receipt_date, currency_code, currency_symbol, total_amount, tax_amount, line_items.',
    'receipt_date must be in YYYY-MM-DD format.',
    `Translate item_name values and category labels into ${outputLanguage}.`,
    'Keep merchant names, product brands, model numbers, SKU-like identifiers, and legally printed proper nouns unchanged when translation would be misleading.',
    `The category field must use only one of these ${outputLanguage} labels: ${localizedCategories.join(', ')}.`,
    `If you are unsure about a category, use ${fallbackCategory}.`,
    'For currency detection, identify the real paid currency printed on the receipt.',
    'When symbols are ambiguous ($, £, ¥, kr, Fr, Rs, etc.), use printed ISO codes, receipt language, merchant country, tax clues, and surrounding context to infer the correct ISO 4217 code.',
    'Do not default to USD unless the receipt explicitly supports USD.',
    'tax_amount must contain the total VAT/KDV/tax amount if present; otherwise use 0.',
    'line_items must include every detected purchased item with item_name, transaction_date, quantity, unit_price, total_price, and category.',
    "If the document is a bank statement or any multi-date list, find each row's own date and write it into transaction_date.",
    'If a row does not have its own date, use the main receipt_date or null for transaction_date.',
    'Return a single JSON object.',
  ].join(' ');
}

async function analyzeReceipt(
  fileInput,
  mimeType,
  { language = DEFAULT_LANGUAGE, storageUrl = null } = {}
) {
  const apiKey = getQwenApiKey();
  if (!apiKey) {
    throw new Error('Qwen API is not configured. Set QWEN_API_KEY.');
  }

  const languageCode = normalizeLanguageCode(language);
  const normalizedMimeType = normalizeReceiptMimeType(
    mimeType,
    typeof fileInput === 'object' ? fileInput?.filename : ''
  );
  if (!normalizedMimeType) {
    throw new Error('Unsupported receipt file type for AI analysis.');
  }

  const mediaPayload = await buildReceiptMediaPayload(
    fileInput,
    normalizedMimeType,
    storageUrl
  );
  const prompt = buildReceiptPrompt(languageCode);
  const schemaGuide = JSON.stringify(buildReceiptSchema(languageCode));

  let response;
  try {
    response = await fetch(QWEN_RECEIPT_ENDPOINT, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: QWEN_RECEIPT_MODEL,
        messages: [
          {
            role: 'system',
            content: `${prompt} Follow this JSON schema guidance exactly: ${schemaGuide}`,
          },
          {
            role: 'user',
            content: [
              mediaPayload,
              {
                type: 'text',
                text: 'Return the receipt analysis as a single JSON object matching the required keys exactly.',
              },
            ],
          },
        ],
        response_format: {
          type: 'json_object',
        },
      }),
    });
  } catch (error) {
    error.message =
      `Qwen receipt analysis request failed for ${normalizedMimeType} (${languageCode}): ${error.message}`;
    throw error;
  }

  const payload = await response.json().catch(async () => ({
    message: await response.text(),
  }));

  if (!response.ok) {
    throw new Error(
      `Qwen receipt analysis failed for ${normalizedMimeType} (${languageCode}): ${formatQwenError(
        payload
      )}`
    );
  }

  const responseText = extractQwenText(payload);
  if (!responseText) {
    throw new Error(
      `Qwen receipt analysis returned an empty response for ${normalizedMimeType} (${languageCode}).`
    );
  }

  try {
    return JSON.parse(stripJsonCodeFences(responseText));
  } catch (error) {
    error.message =
      `Qwen receipt analysis returned invalid JSON for ${normalizedMimeType} (${languageCode}): ${error.message}`;
    throw error;
  }
}

module.exports = {
  analyzeReceipt,
  buildReceiptPrompt,
  buildReceiptSchema,
  getQwenApiKey,
  hasQwenApiKey,
};

async function buildReceiptMediaPayload(fileInput, mimeType, storageUrl = null) {
  if (storageUrl) {
    return { type: 'image_url', image_url: { url: storageUrl } };
  }

  const binary = await resolveReceiptBinary(fileInput, storageUrl);
  const base64File = binary.toString('base64');
  return {
    type: 'image_url',
    image_url: { url: `data:${mimeType};base64,${base64File}` },
  };
}

function extractQwenText(payload) {
  const contentBlocks = payload?.choices?.[0]?.message?.content;
  if (typeof contentBlocks === 'string' && contentBlocks.trim()) {
    return contentBlocks.trim();
  }

  if (!Array.isArray(contentBlocks)) {
    return null;
  }

  const textBlock = contentBlocks.find(
    (block) => typeof block?.text === 'string' && block.text.trim()
  );
  return textBlock?.text?.trim() || null;
}

function formatQwenError(payload) {
  if (typeof payload?.message === 'string' && payload.message.trim()) {
    return payload.message.trim();
  }

  if (typeof payload?.error?.message === 'string' && payload.error.message.trim()) {
    return payload.error.message.trim();
  }

  if (typeof payload?.code === 'string' && payload.code.trim()) {
    return payload.code.trim();
  }

  if (typeof payload?.output?.message === 'string' && payload.output.message.trim()) {
    return payload.output.message.trim();
  }

  return 'Unknown Qwen API error.';
}

function stripJsonCodeFences(text) {
  return text
    .replace(/^```json\s*/i, '')
    .replace(/^```\s*/i, '')
    .replace(/\s*```$/i, '')
    .trim();
}

async function resolveReceiptBinary(fileInput, storageUrl = null) {
  if (Buffer.isBuffer(fileInput)) {
    return fileInput;
  }

  if (fileInput && Buffer.isBuffer(fileInput.buffer)) {
    return fileInput.buffer;
  }

  if (storageUrl || typeof fileInput === 'string') {
    const response = await fetch(storageUrl || fileInput);
    if (!response.ok) {
      throw new Error(
        `Unable to fetch receipt file for AI analysis (${response.status}).`
      );
    }

    const arrayBuffer = await response.arrayBuffer();
    return Buffer.from(arrayBuffer);
  }

  throw new Error('Receipt analysis requires a file buffer or storage URL.');
}
