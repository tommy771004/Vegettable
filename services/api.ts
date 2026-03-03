import { RawProductData, ProductSummary, DailyPrice, MonthlyPrice } from '@/types';
import { toROCDate, daysAgo, yearsAgo, fromROCDate } from '@/utils/date';
import { calcPriceLevel, calcTrend } from '@/utils/price';
import { CROP_ALIASES } from '@/constants/aliases';
import { VEGETABLE_CODE_CATEGORY } from '@/constants/categories';

const BASE_URL = 'https://data.moa.gov.tw/Service/OpenData/FromM/FarmTransData.aspx';

interface FetchOptions {
  startDate?: Date;
  endDate?: Date;
  cropCode?: string;
  cropName?: string;
  market?: string;
  top?: number;
  skip?: number;
}

/** 從農委會 API 取得原始農產品交易資料 */
async function fetchRawData(options: FetchOptions = {}): Promise<RawProductData[]> {
  const params = new URLSearchParams();

  if (options.startDate) params.set('StartDate', toROCDate(options.startDate));
  if (options.endDate) params.set('EndDate', toROCDate(options.endDate));
  if (options.cropCode) params.set('CropCode', options.cropCode);
  if (options.cropName) params.set('CropName', options.cropName);
  if (options.market) params.set('Market', options.market);
  params.set('$top', String(options.top ?? 9999));
  if (options.skip) params.set('$skip', String(options.skip));

  const url = `${BASE_URL}?${params.toString()}`;

  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`API 請求失敗: ${response.status}`);
  }
  return response.json();
}

/**
 * 取得近一週的交易資料，並聚合為產品摘要列表
 */
export async function fetchRecentProducts(): Promise<ProductSummary[]> {
  const endDate = new Date();
  const startDate = daysAgo(10); // 多抓幾天以確保有足夠交易日資料

  const [recentData, historicalSample] = await Promise.all([
    fetchRawData({ startDate, endDate, top: 20000 }),
    fetchHistoricalAverage(),
  ]);

  return aggregateProducts(recentData, historicalSample);
}

/**
 * 取得歷史平均價（近三年同月份資料的平均）
 */
async function fetchHistoricalAverage(): Promise<Map<string, number>> {
  const now = new Date();
  const currentMonth = now.getMonth() + 1;
  const avgMap = new Map<string, number>();

  // 取近三年同月份的資料
  const promises: Promise<RawProductData[]>[] = [];
  for (let y = 1; y <= 3; y++) {
    const yearDate = yearsAgo(y);
    const startDate = new Date(yearDate.getFullYear(), currentMonth - 1, 1);
    const endDate = new Date(yearDate.getFullYear(), currentMonth, 0);
    promises.push(fetchRawData({ startDate, endDate, top: 20000 }));
  }

  const results = await Promise.all(promises);
  const allData = results.flat();

  // 按作物名稱聚合平均價
  const cropTotals = new Map<string, { sum: number; count: number }>();
  for (const item of allData) {
    const name = item.作物名稱;
    const price = Number(item.平均價);
    if (isNaN(price) || price <= 0) continue;
    const existing = cropTotals.get(name) || { sum: 0, count: 0 };
    existing.sum += price;
    existing.count += 1;
    cropTotals.set(name, existing);
  }

  for (const [name, { sum, count }] of cropTotals) {
    avgMap.set(name, sum / count);
  }

  return avgMap;
}

/**
 * 將原始資料聚合為產品摘要
 */
function aggregateProducts(
  rawData: RawProductData[],
  historicalAvg: Map<string, number>
): ProductSummary[] {
  // 按作物名稱分組
  const grouped = new Map<string, RawProductData[]>();
  for (const item of rawData) {
    const name = item.作物名稱;
    if (!grouped.has(name)) grouped.set(name, []);
    grouped.get(name)!.push(item);
  }

  const summaries: ProductSummary[] = [];

  for (const [cropName, items] of grouped) {
    // 按日期分組計算每日平均
    const dailyMap = new Map<string, { priceSum: number; volSum: number; count: number }>();
    let totalPrice = 0;
    let totalCount = 0;
    const cropCode = items[0].作物代號;

    for (const item of items) {
      const price = Number(item.平均價);
      const vol = Number(item.交易量);
      if (isNaN(price) || price <= 0) continue;

      totalPrice += price;
      totalCount += 1;

      const date = item.交易日期;
      const existing = dailyMap.get(date) || { priceSum: 0, volSum: 0, count: 0 };
      existing.priceSum += price;
      existing.volSum += vol;
      existing.count += 1;
      dailyMap.set(date, existing);
    }

    if (totalCount === 0) continue;

    const avgPrice = totalPrice / totalCount;

    // 生成每日價格序列（按日期排序）
    const recentPrices: DailyPrice[] = Array.from(dailyMap.entries())
      .map(([date, data]) => ({
        date,
        avgPrice: Math.round((data.priceSum / data.count) * 10) / 10,
        volume: Math.round(data.volSum),
      }))
      .sort((a, b) => a.date.localeCompare(b.date))
      .slice(-7); // 最近七天

    const historical = historicalAvg.get(cropName) || avgPrice;
    const dailyPricesNum = recentPrices.map((d) => d.avgPrice);

    // 取得前一日均價
    const prevAvgPrice = recentPrices.length >= 2
      ? recentPrices[recentPrices.length - 2].avgPrice
      : avgPrice;

    // 判斷蔬菜子類別
    const subCategory = VEGETABLE_CODE_CATEGORY[cropCode];
    const category = subCategory ? 'vegetable' : inferCategory(cropCode);

    summaries.push({
      cropCode,
      cropName,
      avgPrice: Math.round(avgPrice * 10) / 10,
      prevAvgPrice,
      historicalAvgPrice: Math.round(historical * 10) / 10,
      volume: items.reduce((s, i) => s + Number(i.交易量 || 0), 0),
      priceLevel: calcPriceLevel(avgPrice, historical),
      trend: calcTrend(dailyPricesNum),
      recentPrices,
      category,
      aliases: CROP_ALIASES[cropName] || [],
    });
  }

  return summaries;
}

/**
 * 由作物代號推斷主類別
 */
function inferCategory(cropCode: string): ProductSummary['category'] {
  if (!cropCode) return 'vegetable';
  const prefix = cropCode.charAt(0);
  switch (prefix) {
    case 'L':
    case 'S':
      return 'vegetable';
    case 'F':
      return 'fruit';
    case 'B':
      return 'flower';
    default:
      return 'vegetable';
  }
}

/**
 * 取得特定作物的詳細價格歷史（七日均價 + 三年月均價）
 */
export async function fetchProductDetail(cropName: string): Promise<{
  dailyPrices: DailyPrice[];
  monthlyPrices: MonthlyPrice[];
}> {
  const endDate = new Date();
  const startDate = daysAgo(14);

  // 取近兩週日交易資料
  const recentData = await fetchRawData({
    startDate,
    endDate,
    cropName,
    top: 5000,
  });

  // 每日聚合
  const dailyMap = new Map<string, { priceSum: number; volSum: number; count: number }>();
  for (const item of recentData) {
    const price = Number(item.平均價);
    const vol = Number(item.交易量);
    if (isNaN(price) || price <= 0) continue;
    const date = item.交易日期;
    const existing = dailyMap.get(date) || { priceSum: 0, volSum: 0, count: 0 };
    existing.priceSum += price;
    existing.volSum += vol;
    existing.count += 1;
    dailyMap.set(date, existing);
  }

  const dailyPrices: DailyPrice[] = Array.from(dailyMap.entries())
    .map(([date, data]) => ({
      date,
      avgPrice: Math.round((data.priceSum / data.count) * 10) / 10,
      volume: Math.round(data.volSum),
    }))
    .sort((a, b) => a.date.localeCompare(b.date))
    .slice(-7);

  // 取近三年月均價
  const monthlyPrices: MonthlyPrice[] = [];
  for (let y = 3; y >= 0; y--) {
    const yearDate = y === 0 ? new Date() : yearsAgo(y);
    const year = yearDate.getFullYear();
    const maxMonth = y === 0 ? new Date().getMonth() + 1 : 12;

    for (let m = 1; m <= maxMonth; m++) {
      const monthStart = new Date(year, m - 1, 1);
      const monthEnd = new Date(year, m, 0);

      try {
        const data = await fetchRawData({
          startDate: monthStart,
          endDate: monthEnd,
          cropName,
          top: 5000,
        });

        if (data.length > 0) {
          let sum = 0;
          let volSum = 0;
          let count = 0;
          for (const item of data) {
            const price = Number(item.平均價);
            if (!isNaN(price) && price > 0) {
              sum += price;
              volSum += Number(item.交易量 || 0);
              count += 1;
            }
          }
          if (count > 0) {
            monthlyPrices.push({
              month: toROCDate(monthStart).substring(0, 6).replace('.', '/'),
              avgPrice: Math.round((sum / count) * 10) / 10,
              volume: Math.round(volSum),
            });
          }
        }
      } catch {
        // 跳過失敗的月份
      }
    }
  }

  return { dailyPrices, monthlyPrices };
}

/**
 * 搜尋產品（支援別名搜尋）
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
