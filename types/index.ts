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

/** 設定 */
export interface AppSettings {
  priceUnit: PriceUnit;
  showRetailPrice: boolean;
  favorites: string[];  // cropCode[]
}
