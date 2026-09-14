import { executeSQL } from './snowflake-api';

export interface TranslationResult {
  originalText: string;
  translatedText: string;
  wasTranslated: boolean;
}

export async function detectAndTranslate(text: string): Promise<TranslationResult> {
  const escaped = text.replace(/'/g, "''");

  try {
    // AI_TRANSLATE with empty source language auto-detects and translates to English.
    // If the text is already English, the output will be ~identical.
    const result = await executeSQL(
      `SELECT AI_TRANSLATE('${escaped}', '', 'en') AS translated`
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
