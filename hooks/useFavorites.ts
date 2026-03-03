import { useState, useEffect, useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

const FAVORITES_KEY = '@vegettable_favorites';

export function useFavorites() {
  const [favorites, setFavorites] = useState<string[]>([]);

  useEffect(() => {
    loadFavorites();
  }, []);

  const loadFavorites = async () => {
    try {
      const stored = await AsyncStorage.getItem(FAVORITES_KEY);
      if (stored) {
        setFavorites(JSON.parse(stored));
      }
    } catch {
      // 靜默失敗
    }
  };

  const saveFavorites = async (newFavorites: string[]) => {
    try {
      await AsyncStorage.setItem(FAVORITES_KEY, JSON.stringify(newFavorites));
    } catch {
      // 靜默失敗
    }
  };

  const toggleFavorite = useCallback(
    (cropCode: string) => {
      setFavorites((prev) => {
        const next = prev.includes(cropCode)
          ? prev.filter((c) => c !== cropCode)
          : [...prev, cropCode];
        saveFavorites(next);
        return next;
      });
    },
    []
  );

  const isFavorite = useCallback(
    (cropCode: string) => favorites.includes(cropCode),
    [favorites]
  );

  return { favorites, toggleFavorite, isFavorite };
}
