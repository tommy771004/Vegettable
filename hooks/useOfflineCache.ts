import { useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { ProductSummary } from '@/types';

const CACHE_KEY = '@vegettable_offline_products';
const CACHE_TIMESTAMP_KEY = '@vegettable_offline_timestamp';

/** 離線快取 — 將產品資料存入 AsyncStorage，斷網時可瀏覽 */
export function useOfflineCache() {
  /** 儲存產品資料到離線快取 */
  const saveToCache = useCallback(async (products: ProductSummary[]) => {
    try {
      await AsyncStorage.setItem(CACHE_KEY, JSON.stringify(products));
      await AsyncStorage.setItem(CACHE_TIMESTAMP_KEY, Date.now().toString());
    } catch {
      // 靜默失敗
    }
  }, []);

  /** 從離線快取讀取產品資料 */
  const loadFromCache = useCallback(async (): Promise<{
    products: ProductSummary[];
    timestamp: number | null;
  }> => {
    try {
      const json = await AsyncStorage.getItem(CACHE_KEY);
      const ts = await AsyncStorage.getItem(CACHE_TIMESTAMP_KEY);
      if (!json) return { products: [], timestamp: null };
      return {
        products: JSON.parse(json),
        timestamp: ts ? parseInt(ts, 10) : null,
      };
    } catch {
      return { products: [], timestamp: null };
    }
  }, []);

  /** 快取是否過期 (超過 1 小時) */
  const isCacheStale = useCallback(async (): Promise<boolean> => {
    try {
      const ts = await AsyncStorage.getItem(CACHE_TIMESTAMP_KEY);
      if (!ts) return true;
      return Date.now() - parseInt(ts, 10) > 60 * 60 * 1000;
    } catch {
      return true;
    }
  }, []);

  return { saveToCache, loadFromCache, isCacheStale };
}
