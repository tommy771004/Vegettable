using VegettableApi.Models;

namespace VegettableApi.Services;

/// <summary>
/// 產品服務實作 — 聚合農業部原始資料為前端 DTO
/// </summary>
public class ProductService : IProductService
{
    private readonly IMoaApiService _moaApi;
    private readonly ILogger<ProductService> _logger;

    public ProductService(IMoaApiService moaApi, ILogger<ProductService> logger)
    {
        _moaApi = moaApi;
        _logger = logger;
    }

    public async Task<List<ProductSummaryDto>> GetRecentProductsAsync(string? category = null)
    {
        var endDate = DateTime.Today;
        var startDate = endDate.AddDays(-10); // 多抓幾天確保有足夠交易日

        // 並行取得近期資料與歷史同月資料
        var recentTask = _moaApi.FetchFarmTransDataAsync(startDate, endDate);
        var historicalTask = FetchHistoricalAverageAsync();

        await Task.WhenAll(recentTask, historicalTask);

        var recentData = recentTask.Result;
        var historicalAvg = historicalTask.Result;

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

        // 每日聚合
        var dailyPrices = AggregateDailyPrices(recentData);

        // 取近三年月均價
        var monthlyPrices = await FetchMonthlyPricesAsync(cropName);

        // 歷史同月均價
        var historicalAvg = await FetchHistoricalAverageForCropAsync(cropName);

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
        var allProducts = await GetRecentProductsAsync();
        var kw = keyword.Trim().ToLower();

        return allProducts.Where(p =>
            p.CropName.Contains(kw, StringComparison.OrdinalIgnoreCase) ||
            p.Aliases.Any(a => a.Contains(kw, StringComparison.OrdinalIgnoreCase))
        ).ToList();
    }

    // ─── Private helpers ───────────────────────────────────────

    private async Task<Dictionary<string, decimal>> FetchHistoricalAverageAsync()
    {
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

    private async Task<List<MonthlyPriceDto>> FetchMonthlyPricesAsync(string cropName)
    {
        var now = DateTime.Today;
        var monthlyPrices = new List<MonthlyPriceDto>();

        // 取近三年每月資料 (從三年前到現在)
        for (int y = 3; y >= 0; y--)
        {
            var yearDate = y == 0 ? now : now.AddYears(-y);
            int maxMonth = y == 0 ? now.Month : 12;

            for (int m = 1; m <= maxMonth; m++)
            {
                try
                {
                    var monthStart = new DateTime(yearDate.Year, m, 1);
                    var monthEnd = monthStart.AddMonths(1).AddDays(-1);
                    var data = await _moaApi.FetchFarmTransDataAsync(monthStart, monthEnd, cropName: cropName, top: 5000);

                    var valid = data.Where(d => d.AvgPrice > 0).ToList();
                    if (valid.Count > 0)
                    {
                        monthlyPrices.Add(new MonthlyPriceDto
                        {
                            Month = $"{yearDate.Year}/{m:D2}",
                            AvgPrice = Math.Round(valid.Average(d => d.AvgPrice), 1),
                            Volume = Math.Round(valid.Sum(d => d.Volume), 0),
                        });
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to fetch monthly data for {CropName} {Year}/{Month}", cropName, yearDate.Year, m);
                }
            }
        }

        return monthlyPrices;
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
            .OrderBy(d => d.Date)
            .ToList();
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
        var prefix = cropCode[0];
        return prefix switch
        {
            'L' or 'S' => "vegetable",
            'F' => "fruit",
            'B' => "flower",
            _ => "vegetable",
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
