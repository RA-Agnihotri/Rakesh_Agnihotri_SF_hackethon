import { executeSQLWithBindings } from './snowflake-api';

export interface TranslationResult {
  originalText: string;
  translatedText: string;
  wasTranslated: boolean;
}

export async function detectAndTranslate(text: string): Promise<TranslationResult> {
  try {
    // AI_TRANSLATE with empty source language auto-detects and translates to English.
    // Uses parameterized binding (?) to prevent SQL injection — user text never
    // touches the SQL string.
    const result = await executeSQLWithBindings(
      `SELECT AI_TRANSLATE(?, '', 'en') AS translated`,
      [{ type: 'TEXT', value: text }]
    );

    const translated: string = result.data?.[0]?.[0] ?? text;

    // Heuristic: if the translation is nearly identical, the input was already English.
    const wasTranslated = normalized(translated) !== normalized(text);

    return {
      originalText: text,
      translatedText: wasTranslated ? translated : text,
      wasTranslated,
    };
  } catch {
    // If translation fails, pass through the original text so the user isn't blocked.
    return { originalText: text, translatedText: text, wasTranslated: false };
  }
}

function normalized(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]/g, '');
}
