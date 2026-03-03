import { ProductSummary, DailyPrice, MonthlyPrice } from '@/types';
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
