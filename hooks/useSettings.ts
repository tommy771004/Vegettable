import { useState, useEffect, useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { PriceUnit } from '@/types';

const SETTINGS_KEY = '@vegettable_settings';

interface Settings {
  priceUnit: PriceUnit;
  showRetailPrice: boolean;
}

const DEFAULT_SETTINGS: Settings = {
  priceUnit: 'kg',
  showRetailPrice: false,
};

export function useSettings() {
  const [settings, setSettings] = useState<Settings>(DEFAULT_SETTINGS);

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    try {
      const stored = await AsyncStorage.getItem(SETTINGS_KEY);
      if (stored) {
        setSettings({ ...DEFAULT_SETTINGS, ...JSON.parse(stored) });
      }
    } catch {
      // 靜默失敗
    }
  };

  const updateSettings = useCallback(async (updates: Partial<Settings>) => {
    setSettings((prev) => {
      const next = { ...prev, ...updates };
      AsyncStorage.setItem(SETTINGS_KEY, JSON.stringify(next)).catch(() => {});
      return next;
    });
  }, []);

  const togglePriceUnit = useCallback(() => {
    updateSettings({
      priceUnit: settings.priceUnit === 'kg' ? 'catty' : 'kg',
    });
  }, [settings.priceUnit, updateSettings]);

  const toggleRetailPrice = useCallback(() => {
    updateSettings({
      showRetailPrice: !settings.showRetailPrice,
    });
  }, [settings.showRetailPrice, updateSettings]);

  return {
    settings,
    updateSettings,
    togglePriceUnit,
    toggleRetailPrice,
  };
}
