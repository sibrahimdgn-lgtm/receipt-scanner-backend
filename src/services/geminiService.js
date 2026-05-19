/**
 * Qwen Vision Service
 * Sends receipt images or PDFs to Alibaba Qwen for structured data extraction.
 */

const OpenAI = require('openai');
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

const DEFAULT_QWEN_BASE_URL =
  'https://dashscope-intl.aliyuncs.com/compatible-mode/v1';
const DEFAULT_QWEN_VL_MODEL = 'qwen3-vl-plus';
const DEFAULT_QWEN_TIMEOUT_SECONDS = 120;
const DEFAULT_QWEN_MAX_RETRIES = 2;
const DEFAULT_QWEN_MAX_OUTPUT_TOKENS = 8192;
const PDF_RASTER_SCALE = 2;

let cachedClient = null;
let cachedClientSignature = '';

function getQwenApiKey() {
  return (
    process.env.QWEN_API_KEY?.trim() ||
    process.env.CREATIVE_QWEN_API_KEY?.trim() ||
    process.env.DASHSCOPE_API_KEY?.trim() ||
    null
  );
}

function hasQwenApiKey() {
  return Boolean(getQwenApiKey());
}

function getQwenBaseUrl() {
  return (
    process.env.QWEN_BASE_URL?.trim() ||
    process.env.CREATIVE_QWEN_BASE_URL?.trim() ||
    DEFAULT_QWEN_BASE_URL
  );
}

function getQwenVisionModel() {
  return (
    process.env.QWEN_VL_MODEL?.trim() ||
    process.env.CREATIVE_QWEN_VL_MODEL?.trim() ||
    DEFAULT_QWEN_VL_MODEL
  );
}

function getQwenTimeoutMs() {
  const seconds = Number(
    process.env.QWEN_TIMEOUT?.trim() ||
      process.env.CREATIVE_QWEN_TIMEOUT?.trim() ||
      DEFAULT_QWEN_TIMEOUT_SECONDS
  );
  return Math.max(1, seconds) * 1000;
}

function getQwenMaxRetries() {
  return Number(
    process.env.QWEN_MAX_RETRIES?.trim() ||
      process.env.CREATIVE_QWEN_MAX_RETRIES?.trim() ||
      DEFAULT_QWEN_MAX_RETRIES
  );
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
    throw new Error(
      'Qwen API is not configured. Set QWEN_API_KEY, CREATIVE_QWEN_API_KEY, or DASHSCOPE_API_KEY.'
    );
  }

  const languageCode = normalizeLanguageCode(language);
  const normalizedMimeType = normalizeReceiptMimeType(
    mimeType,
    typeof fileInput === 'object' ? fileInput?.filename : ''
  );
  if (!normalizedMimeType) {
    throw new Error('Unsupported receipt file type for AI analysis.');
  }

  const prompt = buildReceiptPrompt(languageCode);
  const schemaGuide = JSON.stringify(buildReceiptSchema(languageCode));
  const mediaContent = await buildReceiptMediaContent(
    fileInput,
    normalizedMimeType,
    storageUrl
  );

  let completion;
  try {
    completion = await getQwenClient().chat.completions.create({
      model: getQwenVisionModel(),
      messages: [
        {
          role: 'system',
          content: `${prompt} Follow this JSON schema guidance exactly: ${schemaGuide}`,
        },
        {
          role: 'user',
            content: [
              ...mediaContent,
            {
              type: 'text',
              text: 'Return the receipt analysis as a single JSON object matching the required keys exactly.',
            },
          ],
        },
      ],
      response_format: { type: 'json_object' },
      max_tokens: DEFAULT_QWEN_MAX_OUTPUT_TOKENS,
      extra_body: { enable_thinking: false },
    });
  } catch (error) {
    error.message =
      `Qwen receipt analysis request failed for ${normalizedMimeType} (${languageCode}): ${error.message}`;
    throw error;
  }

  const responseText = extractQwenText(completion);
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
  getQwenBaseUrl,
  getQwenVisionModel,
};

function getQwenClient() {
  const apiKey = getQwenApiKey();
  if (!apiKey) {
    throw new Error(
      'Qwen API is not configured. Set QWEN_API_KEY, CREATIVE_QWEN_API_KEY, or DASHSCOPE_API_KEY.'
    );
  }

  const baseURL = getQwenBaseUrl();
  const signature = `${apiKey}::${baseURL}::${getQwenTimeoutMs()}::${getQwenMaxRetries()}`;
  if (cachedClient && cachedClientSignature === signature) {
    return cachedClient;
  }

  cachedClient = new OpenAI({
    apiKey,
    baseURL,
    timeout: getQwenTimeoutMs(),
    maxRetries: getQwenMaxRetries(),
  });
  cachedClientSignature = signature;
  return cachedClient;
}

async function buildReceiptMediaContent(fileInput, mimeType, storageUrl = null) {
  if (mimeType !== 'application/pdf') {
    const imageUrl =
      storageUrl && typeof storageUrl === 'string'
        ? storageUrl
        : await buildSingleImageDataUrl(fileInput, mimeType, storageUrl);

    return [
      {
        type: 'text',
        text: 'Attached image: receipt',
      },
      {
        type: 'image_url',
        image_url: { url: imageUrl },
      },
    ];
  }

  const binary = await resolveReceiptBinary(fileInput, storageUrl);
  const rasterizedPages = await rasterizePdfToDataUrls(binary);

  return rasterizedPages.flatMap((url, index) => [
    {
      type: 'text',
      text: `Attached image: receipt page ${index + 1}`,
    },
    {
      type: 'image_url',
      image_url: { url },
    },
  ]);
}

function extractQwenText(completion) {
  const content = completion?.choices?.[0]?.message?.content;
  if (typeof content === 'string' && content.trim()) {
    return content.trim();
  }

  if (!Array.isArray(content)) {
    return null;
  }

  const textBlock = content.find(
    (block) => typeof block?.text === 'string' && block.text.trim()
  );
  return textBlock?.text?.trim() || null;
}

function stripJsonCodeFences(text) {
  const stripped = text
    .replace(/^```json\s*/i, '')
    .replace(/^```\s*/i, '')
    .replace(/\s*```$/i, '')
    .trim();

  const firstBrace = stripped.indexOf('{');
  const lastBrace = stripped.lastIndexOf('}');
  if (firstBrace >= 0 && lastBrace > firstBrace) {
    return stripped.slice(firstBrace, lastBrace + 1);
  }

  return stripped;
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

async function buildSingleImageDataUrl(fileInput, mimeType, storageUrl = null) {
  const binary = await resolveReceiptBinary(fileInput, storageUrl);
  return `data:${mimeType};base64,${binary.toString('base64')}`;
}

async function rasterizePdfToDataUrls(pdfBuffer) {
  const pdfjs = await import('pdfjs-dist/legacy/build/pdf.mjs');
  const { createCanvas, Path2D, DOMMatrix, ImageData } = require('@napi-rs/canvas');

  global.Path2D = Path2D;
  global.DOMMatrix = DOMMatrix;
  global.ImageData = ImageData;

  const document = await pdfjs.getDocument({
    data: new Uint8Array(pdfBuffer),
    useSystemFonts: true,
  }).promise;

  const pages = [];
  for (let pageNumber = 1; pageNumber <= document.numPages; pageNumber += 1) {
    const page = await document.getPage(pageNumber);
    const viewport = page.getViewport({ scale: PDF_RASTER_SCALE });
    const canvas = createCanvas(
      Math.ceil(viewport.width),
      Math.ceil(viewport.height)
    );
    const context = canvas.getContext('2d');

    await page.render({
      canvasContext: context,
      viewport,
    }).promise;

    pages.push(`data:image/png;base64,${canvas.toBuffer('image/png').toString('base64')}`);
  }

  return pages;
}
