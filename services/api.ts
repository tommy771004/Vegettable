import {
  ProductSummary, DailyPrice, MonthlyPrice,
  Market, MarketPrice, PriceAlert, PricePrediction,
  SeasonalInfo, Recipe,
} from '@/types';
import { API_BASE_URL, API_ENDPOINTS } from '@/constants/api';

// ─── Types matching .NET API response ────────────────────────

/** .NET API 統一回應格式 */
interface ApiResponse<T> {
  success: boolean;
  data: T | null;
  message: string | null;
  timestamp: number;
}

/** 後端回傳的產品摘要 DTO */
interface ProductSummaryDto {
  cropCode: string;
  cropName: string;
  avgPrice: number;
  prevAvgPrice: number;
  historicalAvgPrice: number;
  volume: number;
  priceLevel: string;
  trend: string;
  recentPrices: DailyPriceDto[];
  category: string;
  subCategory: string | null;
  aliases: string[];
}

interface DailyPriceDto {
  date: string;
  avgPrice: number;
  volume: number;
}

interface MonthlyPriceDto {
  month: string;
  avgPrice: number;
  volume: number;
}

/** 後端回傳的產品詳情 DTO */
interface ProductDetailDto {
  cropCode: string;
  cropName: string;
  aliases: string[];
  category: string;
  subCategory: string | null;
  avgPrice: number;
  historicalAvgPrice: number;
  priceLevel: string;
  trend: string;
  dailyPrices: DailyPriceDto[];
  monthlyPrices: MonthlyPriceDto[];
}

// ─── API Client ──────────────────────────────────────────────

async function apiGet<T>(endpoint: string, params?: Record<string, string>): Promise<T> {
  let url = `${API_BASE_URL}${endpoint}`;

  if (params) {
    const searchParams = new URLSearchParams(params);
    url += `?${searchParams.toString()}`;
  }

  const response = await fetch(url, {
    method: 'GET',
    headers: { Accept: 'application/json' },
  });

  if (!response.ok) {
    const errorBody = await response.text().catch(() => '');
    throw new Error(`API 請求失敗 (${response.status}): ${errorBody || response.statusText}`);
  }

  const apiResponse: ApiResponse<T> = await response.json();

  if (!apiResponse.success || apiResponse.data === null) {
    throw new Error(apiResponse.message || '資料取得失敗');
  }

  return apiResponse.data;
}

// ─── Mapper: DTO → Frontend Model ────────────────────────────

function mapToProductSummary(dto: ProductSummaryDto): ProductSummary {
  return {
    cropCode: dto.cropCode,
    cropName: dto.cropName,
    avgPrice: dto.avgPrice,
    prevAvgPrice: dto.prevAvgPrice,
    historicalAvgPrice: dto.historicalAvgPrice,
    volume: dto.volume,
    priceLevel: dto.priceLevel as ProductSummary['priceLevel'],
    trend: dto.trend as ProductSummary['trend'],
    recentPrices: dto.recentPrices.map(mapToDailyPrice),
    category: dto.category as ProductSummary['category'],
    aliases: dto.aliases,
  };
}

function mapToDailyPrice(dto: DailyPriceDto): DailyPrice {
  return {
    date: dto.date,
    avgPrice: dto.avgPrice,
    volume: dto.volume,
  };
}

function mapToMonthlyPrice(dto: MonthlyPriceDto): MonthlyPrice {
  return {
    month: dto.month,
    avgPrice: dto.avgPrice,
    volume: dto.volume,
  };
}

// ─── Public API Functions ────────────────────────────────────

/**
 * 取得近期產品行情列表（已由後端聚合、排序）
 * @param category 可選的主類別篩選
 */
export async function fetchRecentProducts(category?: string): Promise<ProductSummary[]> {
  const params: Record<string, string> = {};
  if (category && category !== 'all') {
    params.category = category;
  }

  const dtos = await apiGet<ProductSummaryDto[]>(API_ENDPOINTS.products, params);
  return dtos.map(mapToProductSummary);
}

/**
 * 取得特定作物的詳細價格歷史（七日均價 + 三年月均價）
 */
export async function fetchProductDetail(cropName: string): Promise<{
  dailyPrices: DailyPrice[];
  monthlyPrices: MonthlyPrice[];
}> {
  const dto = await apiGet<ProductDetailDto>(
    `${API_ENDPOINTS.productDetail}/${encodeURIComponent(cropName)}`
  );

  return {
    dailyPrices: dto.dailyPrices.map(mapToDailyPrice),
    monthlyPrices: dto.monthlyPrices.map(mapToMonthlyPrice),
  };
}

/**
 * 搜尋產品（由後端處理別名搜尋）
 */
export async function searchProductsFromApi(keyword: string): Promise<ProductSummary[]> {
  const dtos = await apiGet<ProductSummaryDto[]>(API_ENDPOINTS.searchProducts, {
    keyword,
  });
  return dtos.map(mapToProductSummary);
}

/**
 * 前端本地搜尋（在已載入的產品列表中篩選，支援別名）
 */
export function searchProducts(
  products: ProductSummary[],
  keyword: string
): ProductSummary[] {
  const kw = keyword.trim().toLowerCase();
  if (!kw) return products;

  return products.filter((p) => {
    if (p.cropName.toLowerCase().includes(kw)) return true;
    if (p.aliases.some((a) => a.toLowerCase().includes(kw))) return true;
    return false;
  });
}

// ─── 市場 API ────────────────────────────────────────────────

/** 取得批發市場清單 */
export async function fetchMarkets(): Promise<Market[]> {
  return apiGet<Market[]>(API_ENDPOINTS.markets);
}

/** 取得指定市場行情 */
export async function fetchMarketPrices(
  marketName: string, cropName?: string
): Promise<MarketPrice[]> {
  const params: Record<string, string> = {};
  if (cropName) params.cropName = cropName;
  return apiGet<MarketPrice[]>(
    `${API_ENDPOINTS.marketPrices}/${encodeURIComponent(marketName)}/prices`, params
  );
}

/** 比較多個市場同一產品價格 */
export async function compareMarketPrices(
  cropName: string, markets?: string[]
): Promise<MarketPrice[]> {
  const params: Record<string, string> = {};
  if (markets?.length) params.markets = markets.join(',');
  return apiGet<MarketPrice[]>(
    `${API_ENDPOINTS.marketCompare}/${encodeURIComponent(cropName)}`, params
  );
}

// ─── 價格警示 API ────────────────────────────────────────────

/** 取得裝置的所有警示 */
export async function fetchAlerts(deviceToken: string): Promise<PriceAlert[]> {
  return apiGet<PriceAlert[]>(API_ENDPOINTS.alerts, { deviceToken });
}

/** 建立新的價格警示 */
export async function createAlert(payload: {
  deviceToken: string;
  cropName: string;
  targetPrice: number;
  condition: 'below' | 'above';
}): Promise<PriceAlert> {
  const url = `${API_BASE_URL}${API_ENDPOINTS.alerts}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify(payload),
  });
  const json: ApiResponse<PriceAlert> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message || '建立失敗');
  return json.data;
}

/** 刪除警示 */
export async function deleteAlert(id: number, deviceToken: string): Promise<void> {
  const url = `${API_BASE_URL}${API_ENDPOINTS.alerts}/${id}?deviceToken=${encodeURIComponent(deviceToken)}`;
  await fetch(url, { method: 'DELETE' });
}

/** 切換警示啟用 */
export async function toggleAlert(id: number, deviceToken: string): Promise<void> {
  const url = `${API_BASE_URL}${API_ENDPOINTS.alerts}/${id}/toggle?deviceToken=${encodeURIComponent(deviceToken)}`;
  await fetch(url, { method: 'PATCH' });
}

// ─── AI 預測 / 季節 / 食譜 API ──────────────────────────────

/** AI 價格預測 */
export async function fetchPrediction(cropName: string): Promise<PricePrediction> {
  return apiGet<PricePrediction>(
    `${API_ENDPOINTS.prediction}/${encodeURIComponent(cropName)}`
  );
}

/** 季節性資訊 */
export async function fetchSeasonalInfo(category?: string): Promise<SeasonalInfo[]> {
  const params: Record<string, string> = {};
  if (category) params.category = category;
  return apiGet<SeasonalInfo[]>(API_ENDPOINTS.seasonal, params);
}

/** 食譜推薦 */
export async function fetchRecipes(cropName: string): Promise<Recipe[]> {
  return apiGet<Recipe[]>(
    `${API_ENDPOINTS.recipes}/${encodeURIComponent(cropName)}/recipes`
  );
}

// ─── 健康檢查 ────────────────────────────────────────────────

export async function checkHealth(): Promise<boolean> {
  try {
    const res = await fetch(`${API_BASE_URL}${API_ENDPOINTS.health}`, { method: 'GET' });
    return res.ok;
  } catch {
    return false;
  }
}
