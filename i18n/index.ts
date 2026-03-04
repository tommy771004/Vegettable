import { useCallback, useMemo } from 'react';
import { useSettings } from '@/hooks/useSettings';
import zhTW from './locales/zh-TW';
import en from './locales/en';
import vi from './locales/vi';
import id from './locales/id';

type TranslationKey = keyof typeof zhTW;

const translations: Record<string, Record<string, string>> = {
  'zh-TW': zhTW,
  en,
  vi,
  id,
};

export const LANGUAGE_OPTIONS = [
  { key: 'zh-TW', label: '繁體中文' },
  { key: 'en', label: 'English' },
  { key: 'vi', label: 'Tiếng Việt' },
  { key: 'id', label: 'Bahasa Indonesia' },
] as const;

/** 多語言 hook — 根據設定回傳對應語言的翻譯函式 */
export function useI18n() {
  const { settings, updateSettings } = useSettings();
  const lang = settings.language || 'zh-TW';
  const dict = useMemo(() => translations[lang] || translations['zh-TW'], [lang]);

  /** 取得翻譯字串，支援 {key} 插值 */
  const t = useCallback(
    (key: TranslationKey, params?: Record<string, string | number>) => {
      let text = dict[key] || zhTW[key] || key;
      if (params) {
        Object.entries(params).forEach(([k, v]) => {
          text = text.replace(`{${k}}`, String(v));
        });
      }
      return text;
    },
    [dict]
  );

  const setLanguage = useCallback(
    (newLang: 'zh-TW' | 'en' | 'vi' | 'id') => {
      updateSettings({ language: newLang });
    },
    [updateSettings]
  );

  return { t, lang, setLanguage };
}
