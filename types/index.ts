/** 聚合後的產品摘要（全市場平均）— 由 .NET 後端回傳 */
export interface ProductSummary {
  cropCode: string;
  cropName: string;
  avgPrice: number;
  prevAvgPrice: number;
  historicalAvgPrice: number;
  volume: number;
  priceLevel: PriceLevel;
  trend: PriceTrend;
  recentPrices: DailyPrice[];
  category: CropCategory;
  aliases: string[];
}

export interface DailyPrice {
  date: string;
  avgPrice: number;
  volume: number;
}

export interface MonthlyPrice {
  month: string;
  avgPrice: number;
  volume: number;
}

/** 價格等級：相對歷史便宜到偏貴 */
export type PriceLevel = 'very-cheap' | 'cheap' | 'normal' | 'expensive';

/** 價格趨勢 */
export type PriceTrend = 'up' | 'down' | 'stable';

/** 蔬菜細分類 */
export type VegetableSubCategory =
  | 'root'      // 根莖類
  | 'leafy'     // 葉菜類
  | 'flower'    // 花果菜類
  | 'mushroom'  // 菇菌類
  | 'pickled';  // 醃漬類

/** 主要產品類型 */
export type CropCategory =
  | 'vegetable'  // 蔬菜
  | 'fruit'      // 水果
  | 'fish'       // 漁產
  | 'meat'       // 肉品
  | 'flower'     // 花卉
  | 'rice';      // 白米

/** 價格單位 */
export type PriceUnit = 'kg' | 'catty';  // 公斤 / 台斤

/** 市場資訊 */
export interface Market {
  marketCode: string;
  marketName: string;
  region: string;
}

/** 市場行情 */
export interface MarketPrice {
  marketName: string;
  cropName: string;
  avgPrice: number;
  upperPrice: number;
  lowerPrice: number;
  volume: number;
  transDate: string;
}

/** 價格警示 */
export interface PriceAlert {
  id: number;
  cropName: string;
  targetPrice: number;
  condition: 'below' | 'above';
  isActive: boolean;
  lastTriggeredAt: string | null;
  createdAt: string;
}

/** AI 價格預測 */
export interface PricePrediction {
  cropName: string;
  currentPrice: number;
  predictedPrice: number;
  changePercent: number;
  direction: 'up' | 'down' | 'stable';
  confidence: number;
  reasoning: string;
}

/** 季節性資訊 */
export interface SeasonalInfo {
  cropName: string;
  category: string;
  peakMonths: number[];
  isInSeason: boolean;
  seasonNote: string;
}

/** 食譜 */
export interface Recipe {
  name: string;
  description: string;
  ingredients: string[];
  difficulty: 'easy' | 'medium' | 'hard';
  cookTimeMinutes: number;
}

/** 設定 */
export interface AppSettings {
  priceUnit: PriceUnit;
  showRetailPrice: boolean;
  favorites: string[];  // cropCode[]
  darkMode: 'system' | 'light' | 'dark';
  language: 'zh-TW' | 'en' | 'vi' | 'id';
  selectedMarket: string | null; // null = 全台平均
}
