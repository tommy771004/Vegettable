import { PriceLevel, PriceTrend, PriceUnit } from '@/types';

/**
 * 公斤轉台斤 (1 台斤 = 0.6 公斤)
 * 批發價以 元/公斤 計，轉為 元/台斤 需乘以 0.6
 */
export function kgToCatty(pricePerKg: number): number {
  return Math.round(pricePerKg * 0.6 * 10) / 10;
}

/** 依據單位轉換價格 */
export function convertPrice(pricePerKg: number, unit: PriceUnit): number {
  return unit === 'catty' ? kgToCatty(pricePerKg) : Math.round(pricePerKg * 10) / 10;
}

/** 粗估零售價（批發價 × 2.5） */
export function estimateRetailPrice(wholesalePrice: number): number {
  return Math.round(wholesalePrice * 2.5 * 10) / 10;
}

/**
 * 計算價格等級
 * 以當前平均價與近三年歷史平均價的比率來判斷
 * ratio < 0.7  → very-cheap (紅色，當令便宜)
 * ratio < 0.9  → cheap (淺紅，相對便宜)
 * ratio < 1.15 → normal-expensive (淺藍，略偏貴)
 * ratio >= 1.15 → expensive (藍色，偏貴)
 */
export function calcPriceLevel(currentAvg: number, historicalAvg: number): PriceLevel {
  if (historicalAvg <= 0) return 'normal-expensive';
  const ratio = currentAvg / historicalAvg;
  if (ratio < 0.7) return 'very-cheap';
  if (ratio < 0.9) return 'cheap';
  if (ratio < 1.15) return 'normal-expensive';
  return 'expensive';
}

/**
 * 計算價格趨勢（近三日）
 * 比較最新一日與前一日的價格
 */
export function calcTrend(recentPrices: number[]): PriceTrend {
  if (recentPrices.length < 2) return 'stable';
  const latest = recentPrices[recentPrices.length - 1];
  const prev = recentPrices[recentPrices.length - 2];
  const diff = latest - prev;
  const threshold = prev * 0.02; // 2% 門檻
  if (diff > threshold) return 'up';
  if (diff < -threshold) return 'down';
  return 'stable';
}

/** 格式化價格顯示 */
export function formatPrice(price: number): string {
  if (price >= 100) return Math.round(price).toString();
  return price.toFixed(1);
}

/** 取得價格單位文字 */
export function getPriceUnitLabel(unit: PriceUnit): string {
  return unit === 'kg' ? '元/公斤' : '元/台斤';
}
