using System.Globalization;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using VegettableApi.Models;

namespace VegettableApi.Services;

/// <summary>
/// 產品服務實作 — 聚合農業部原始資料為前端 DTO
/// </summary>
public class ProductService : IProductService
{
    private readonly IMoaApiService _moaApi;
    private readonly ILogger<ProductService> _logger;
    private readonly IMemoryCache _cache;

    public ProductService(IMoaApiService moaApi, ILogger<ProductService> logger, IMemoryCache cache)
    {
        _moaApi = moaApi;
        _logger = logger;
        _cache = cache;
    }

    public async Task<List<ProductSummaryDto>> GetRecentProductsAsync(string? category = null)
    {
        var endDate = DateTime.Today;
        var startDate = endDate.AddDays(-10); // 多抓幾天確保有足夠交易日

        // 並行取得近期資料與歷史同月資料
        var recentTask = _moaApi.FetchFarmTransDataAsync(startDate, endDate);
        var historicalTask = FetchHistoricalAverageAsync();

        await Task.WhenAll(recentTask, historicalTask);

        var recentData = await recentTask;
        var historicalAvg = await historicalTask;

        var summaries = AggregateToSummaries(recentData, historicalAvg);

        // 依類別篩選
        if (!string.IsNullOrWhiteSpace(category))
        {
            summaries = summaries.Where(s => s.Category == category).ToList();
        }

        // 依便宜程度排序（越便宜越前面）
        return summaries
            .OrderBy(s => GetPriceLevelOrder(s.PriceLevel))
            .ThenBy(s => s.CropName)
            .ToList();
    }

    public async Task<ProductDetailDto> GetProductDetailAsync(string cropName)
    {
        // 取近14天日交易資料
        var endDate = DateTime.Today;
        var startDate = endDate.AddDays(-14);
        var recentData = await _moaApi.FetchFarmTransDataAsync(startDate, endDate, cropName: cropName, top: 5000);

        if (recentData.Count == 0)
            throw new KeyNotFoundException($"找不到作物「{cropName}」的交易資料");

        // 每日聚合
        var dailyPrices = AggregateDailyPrices(recentData);

        // 並行取得月均價與歷史均價
        var monthlyTask = FetchMonthlyPricesAsync(cropName);
        var historicalTask = FetchHistoricalAverageForCropAsync(cropName);
        await Task.WhenAll(monthlyTask, historicalTask);

        var monthlyPrices = await monthlyTask;
        var historicalAvg = await historicalTask;

        // 計算當前均價
        decimal avgPrice = dailyPrices.Count > 0
            ? dailyPrices.TakeLast(3).Average(d => d.AvgPrice)
            : 0;

        // 趨勢
        var trend = CalcTrend(dailyPrices.Select(d => d.AvgPrice).ToList());
        var priceLevel = CalcPriceLevel(avgPrice, historicalAvg);

        var cropCode = recentData.FirstOrDefault()?.CropCode ?? "";
        var aliases = CropAliases.GetAliases(cropName);
        var category = InferCategory(cropCode);
        var subCategory = VegetableCategories.GetSubCategory(cropCode);

        return new ProductDetailDto
        {
            CropCode = cropCode,
            CropName = cropName,
            Aliases = aliases,
            Category = category,
            SubCategory = subCategory,
            AvgPrice = Math.Round(avgPrice, 1),
            HistoricalAvgPrice = Math.Round(historicalAvg, 1),
            PriceLevel = priceLevel,
            Trend = trend,
            DailyPrices = dailyPrices.TakeLast(7).ToList(),
            DailyPricesForPrediction = dailyPrices,
            MonthlyPrices = monthlyPrices,
        };
    }

    public List<CategoryDto> GetCategories()
    {
        return new List<CategoryDto>
        {
            new()
            {
                Key = "vegetable",
                Label = "蔬菜",
                Icon = "leaf",
                SubCategories = new List<SubCategoryDto>
                {
                    new() { Key = "root", Label = "根莖類", Icon = "nutrition" },
                    new() { Key = "leafy", Label = "葉菜類", Icon = "leaf" },
                    new() { Key = "flower-fruit", Label = "花果菜類", Icon = "flower" },
                    new() { Key = "mushroom", Label = "菇菌類", Icon = "cloudy" },
                    new() { Key = "pickled", Label = "醃漬類", Icon = "flask" },
                }
            },
            new() { Key = "fruit", Label = "水果", Icon = "nutrition" },
            new() { Key = "flower", Label = "花卉", Icon = "flower" },
            new() { Key = "fish", Label = "漁產", Icon = "fish" },
            new() { Key = "poultry", Label = "畜禽", Icon = "paw" },
            new() { Key = "rice", Label = "白米", Icon = "restaurant" },
        };
    }

    public async Task<List<ProductSummaryDto>> SearchProductsAsync(string keyword)
    {
        var cacheKey = "all_products_summary";
        if (!_cache.TryGetValue(cacheKey, out List<ProductSummaryDto>? allProducts) || allProducts is null)
        {
            allProducts = await GetRecentProductsAsync();
            _cache.Set(cacheKey, allProducts, TimeSpan.FromMinutes(30));
        }
        var kw = keyword.Trim().ToLower();

        return allProducts.Where(p =>
            p.CropName.Contains(kw, StringComparison.OrdinalIgnoreCase) ||
            p.Aliases.Any(a => a.Contains(kw, StringComparison.OrdinalIgnoreCase))
        ).ToList();
    }

    public async Task<PaginatedResponse<ProductSummaryDto>> GetRecentProductsPaginatedAsync(
        string? category = null, int offset = 0, int limit = 20)
    {
        // 驗證分頁參數
        limit = Math.Max(1, Math.Min(limit, 100)); // 限制 1-100
        offset = Math.Max(0, offset);

        var allProducts = await GetRecentProductsAsync(category);
        var total = allProducts.Count;
        var items = allProducts.Skip(offset).Take(limit).ToList();

        return new PaginatedResponse<ProductSummaryDto>
        {
            Items = items,
            Offset = offset,
            Limit = limit,
            Total = total,
            HasMore = offset + limit < total,
        };
    }

    public async Task<PaginatedResponse<ProductSummaryDto>> SearchProductsPaginatedAsync(
        string keyword, int offset = 0, int limit = 20)
    {
        // 驗證分頁參數
        limit = Math.Max(1, Math.Min(limit, 100));
        offset = Math.Max(0, offset);

        var results = await SearchProductsAsync(keyword);
        var total = results.Count;
        var items = results.Skip(offset).Take(limit).ToList();

        return new PaginatedResponse<ProductSummaryDto>
        {
            Items = items,
            Offset = offset,
            Limit = limit,
            Total = total,
            HasMore = offset + limit < total,
        };
    }

    // ─── Private helpers ───────────────────────────────────────

    private async Task<Dictionary<string, decimal>> FetchHistoricalAverageAsync()
    {
        var cacheKey = $"historical_avg_{DateTime.Today.Month}";
        if (_cache.TryGetValue(cacheKey, out Dictionary<string, decimal>? cached) && cached is not null)
            return cached;

        var now = DateTime.Today;
        var currentMonth = now.Month;
        var avgMap = new Dictionary<string, decimal>();

        var tasks = new List<Task<List<MoaRawData>>>();
        for (int y = 1; y <= 3; y++)
        {
            var yearDate = now.AddYears(-y);
            var monthStart = new DateTime(yearDate.Year, currentMonth, 1);
            var monthEnd = monthStart.AddMonths(1).AddDays(-1);
            tasks.Add(_moaApi.FetchFarmTransDataAsync(monthStart, monthEnd));
        }

        var results = await Task.WhenAll(tasks);
        var allData = results.SelectMany(r => r).ToList();

        var grouped = allData
            .Where(d => d.AvgPrice > 0)
            .GroupBy(d => d.CropName);

        foreach (var group in grouped)
        {
            avgMap[group.Key] = Math.Round(group.Average(g => g.AvgPrice), 1);
        }

        _cache.Set(cacheKey, avgMap, TimeSpan.FromMinutes(60));
        return avgMap;
    }

    private async Task<decimal> FetchHistoricalAverageForCropAsync(string cropName)
    {
        var now = DateTime.Today;
        var tasks = new List<Task<List<MoaRawData>>>();

        for (int y = 1; y <= 3; y++)
        {
            var yearDate = now.AddYears(-y);
            var monthStart = new DateTime(yearDate.Year, now.Month, 1);
            var monthEnd = monthStart.AddMonths(1).AddDays(-1);
            tasks.Add(_moaApi.FetchFarmTransDataAsync(monthStart, monthEnd, cropName: cropName, top: 5000));
        }

        var results = await Task.WhenAll(tasks);
        var allData = results.SelectMany(r => r).Where(d => d.AvgPrice > 0).ToList();

        return allData.Count > 0 ? Math.Round(allData.Average(d => d.AvgPrice), 1) : 0;
    }

    /// <summary>
    /// 批次取得近三年月均價 — 以「年」為單位並行取得，避免逐月 N+1 呼叫
    /// </summary>
    private async Task<List<MonthlyPriceDto>> FetchMonthlyPricesAsync(string cropName)
    {
        var now = DateTime.Today;

        // 以年為單位並行取得（共 4 次呼叫：近三年 + 今年）
        var yearTasks = new List<(int Year, Task<List<MoaRawData>> Task)>();
        for (int y = 3; y >= 0; y--)
        {
            var targetYear = now.AddYears(-y).Year;
            var yearStart = new DateTime(targetYear, 1, 1);
            var yearEnd = y == 0
                ? new DateTime(targetYear, now.Month, DateTime.DaysInMonth(targetYear, now.Month))
                : new DateTime(targetYear, 12, 31);

            yearTasks.Add((targetYear, _moaApi.FetchFarmTransDataAsync(yearStart, yearEnd, cropName: cropName, top: 20000)));
        }

        try
        {
            await Task.WhenAll(yearTasks.Select(t => t.Task));
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "部分年度資料取得失敗: {CropName}", cropName);
        }

        var monthlyPrices = new List<MonthlyPriceDto>();

        foreach (var (year, task) in yearTasks)
        {
            if (task.IsFaulted) continue;

            List<MoaRawData> yearData;
            try { yearData = await task; }
            catch { continue; }

            // 將整年資料依月份分組聚合
            var byMonth = yearData
                .Where(d => d.AvgPrice > 0)
                .GroupBy(d => ParseMonth(d.TransDate))
                .Where(g => g.Key > 0)
                .OrderBy(g => g.Key);

            foreach (var monthGroup in byMonth)
            {
                monthlyPrices.Add(new MonthlyPriceDto
                {
                    Month = $"{year}/{monthGroup.Key:D2}",
                    AvgPrice = Math.Round(monthGroup.Average(d => d.AvgPrice), 1),
                    Volume = Math.Round(monthGroup.Sum(d => d.Volume), 0),
                });
            }
        }

        return monthlyPrices;
    }

    /// <summary>
    /// 從民國年日期字串 (如 "112.03.15") 解析出月份
    /// </summary>
    private static int ParseMonth(string rocDate)
    {
        var parts = rocDate.Split('.');
        if (parts.Length >= 2 && int.TryParse(parts[1], out var month))
            return month;
        return 0;
    }

    private List<ProductSummaryDto> AggregateToSummaries(
        List<MoaRawData> rawData,
        Dictionary<string, decimal> historicalAvg)
    {
        var grouped = rawData
            .Where(d => d.AvgPrice > 0)
            .GroupBy(d => d.CropName);

        var summaries = new List<ProductSummaryDto>();

        foreach (var group in grouped)
        {
            var cropName = group.Key;
            var items = group.ToList();
            var cropCode = items.First().CropCode;

            var avgPrice = Math.Round(items.Average(i => i.AvgPrice), 1);
            var totalVol = Math.Round(items.Sum(i => i.Volume), 0);

            var dailyPrices = AggregateDailyPrices(items);

            var prevAvgPrice = dailyPrices.Count >= 2
                ? dailyPrices[^2].AvgPrice
                : avgPrice;

            var historical = historicalAvg.GetValueOrDefault(cropName, avgPrice);
            var priceLevel = CalcPriceLevel(avgPrice, historical);
            var trend = CalcTrend(dailyPrices.Select(d => d.AvgPrice).ToList());

            var category = InferCategory(cropCode);
            var subCategory = VegetableCategories.GetSubCategory(cropCode);

            summaries.Add(new ProductSummaryDto
            {
                CropCode = cropCode,
                CropName = cropName,
                AvgPrice = avgPrice,
                PrevAvgPrice = prevAvgPrice,
                HistoricalAvgPrice = historical,
                Volume = totalVol,
                PriceLevel = priceLevel,
                Trend = trend,
                RecentPrices = dailyPrices.TakeLast(7).ToList(),
                Category = category,
                SubCategory = subCategory,
                Aliases = CropAliases.GetAliases(cropName),
            });
        }

        return summaries;
    }

    private static List<DailyPriceDto> AggregateDailyPrices(List<MoaRawData> items)
    {
        return items
            .GroupBy(i => i.TransDate)
            .Select(g => new DailyPriceDto
            {
                Date = g.Key,
                AvgPrice = Math.Round(g.Average(i => i.AvgPrice), 1),
                Volume = Math.Round(g.Sum(i => i.Volume), 0),
            })
            .OrderBy(d => ParseRocDateToSortKey(d.Date))
            .ToList();
    }

    /// <summary>
    /// 將民國年日期 "112.03.15" 轉為可排序的整數 1120315
    /// </summary>
    private static int ParseRocDateToSortKey(string rocDate)
    {
        var parts = rocDate.Replace("/", ".").Split('.');
        if (parts.Length >= 3 &&
            int.TryParse(parts[0], out var y) &&
            int.TryParse(parts[1], out var m) &&
            int.TryParse(parts[2], out var d))
        {
            return y * 10000 + m * 100 + d;
        }
        return 0;
    }

    /// <summary>
    /// 價格相對等級：與歷史同月均價相比
    /// </summary>
    private static string CalcPriceLevel(decimal current, decimal historical)
    {
        if (historical <= 0) return "normal";
        var ratio = current / historical;
        return ratio switch
        {
            <= 0.7m => "very-cheap",    // 紅色 — 非常便宜
            <= 0.9m => "cheap",         // 淺紅 — 偏便宜
            <= 1.15m => "normal",       // 淺藍 — 正常偏貴
            _ => "expensive",           // 藍色 — 偏貴
        };
    }

    /// <summary>
    /// 近三日價格趨勢
    /// </summary>
    private static string CalcTrend(List<decimal> prices)
    {
        if (prices.Count < 2) return "stable";
        var recent = prices.TakeLast(3).ToList();
        if (recent.Count < 2) return "stable";

        var first = recent.First();
        var last = recent.Last();
        if (first <= 0) return "stable";

        var change = (last - first) / first;
        return change switch
        {
            > 0.03m => "up",
            < -0.03m => "down",
            _ => "stable",
        };
    }

    /// <summary>
    /// 由作物代號推斷主類別
    /// </summary>
    private static string InferCategory(string cropCode)
    {
        if (string.IsNullOrEmpty(cropCode)) return "vegetable";
        return cropCode[0] switch
        {
            'L' or 'S' => "vegetable",
            'F'        => "fruit",
            'B'        => "flower",
            'A'        => "fish",       // 漁產
            'P'        => "poultry",    // 畜禽
            'R'        => "rice",       // 白米
            _          => "vegetable",
        };
    }

    private static int GetPriceLevelOrder(string level) => level switch
    {
        "very-cheap" => 0,
        "cheap" => 1,
        "normal" => 2,
        "expensive" => 3,
        _ => 2,
    };
}
