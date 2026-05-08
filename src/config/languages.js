const SUPPORTED_LANGUAGES = ['tr', 'en', 'de', 'ar'];
const DEFAULT_LANGUAGE = 'tr';

const LANGUAGE_METADATA = {
  tr: {
    code: 'tr',
    nativeName: 'Turkce',
    promptName: 'Turkish (Turkce)',
  },
  en: {
    code: 'en',
    nativeName: 'English',
    promptName: 'English',
  },
  de: {
    code: 'de',
    nativeName: 'Deutsch',
    promptName: 'German (Deutsch)',
  },
  ar: {
    code: 'ar',
    nativeName: 'العربية',
    promptName: 'Arabic (العربية)',
  },
};

function normalizeLanguageCode(value, fallback = DEFAULT_LANGUAGE) {
  if (value == null) {
    return fallback;
  }

  const token = value
    .toString()
    .trim()
    .split(',')[0]
    .split(';')[0]
    .split(/[-_]/)[0]
    .toLowerCase();

  return SUPPORTED_LANGUAGES.includes(token) ? token : fallback;
}

module.exports = {
  DEFAULT_LANGUAGE,
  LANGUAGE_METADATA,
  SUPPORTED_LANGUAGES,
  normalizeLanguageCode,
};
