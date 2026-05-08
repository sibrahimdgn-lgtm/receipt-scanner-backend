require('dotenv').config();
const { GoogleGenAI } = require('@google/genai');

const ai = new GoogleGenAI({ 
  apiKey: process.env.GEMINI_API_KEY 
});

async function test() {
  const models = ['models/gemini-2.0-flash', 'models/gemini-2.5-flash'];
  const testConfigs = [
    { label: 'Basic Config', config: { responseMimeType: 'application/json' } },
    { label: 'Deep Config', config: { generationConfig: { responseMimeType: 'application/json' } } },
    { label: 'Snake Case', config: { response_mime_type: 'application/json' } }
  ];

  for (const modelId of models) {
    console.log(`--- Testing model: ${modelId} ---`);
    for (const item of testConfigs) {
      try {
        console.log(`Trying ${item.label}...`);
        const response = await ai.models.generateContent({
          model: modelId,
          contents: 'Return a JSON with {"status": "ok"}',
          config: item.config
        });
        console.log(`SUCCESS with ${modelId} / ${item.label}: ${response.text}`);
        return; // Stop on first success
      } catch (e) {
        console.error(`FAILED with ${modelId} / ${item.label}: ${e.message}`);
      }
    }
  }
}

test();
