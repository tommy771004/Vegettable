using Microsoft.EntityFrameworkCore;
using VegettableApi.Data;
using VegettableApi.Data.Entities;
using VegettableApi.Models;

namespace VegettableApi.Services;

/// <summary>
/// 產品服務實作 — 聚合農業部原始資料為前端可用格式
/// </summary>
public class ProductService : IProductService
{
    private readonly IMoaApiService _moaApi;
    private readonly AppDbContext _db;
    private readonly ILogger<ProductService> _logger;

    public ProductService(IMoaApiService moaApi, AppDbContext db, ILogger<ProductService> logger)
    {
        _moaApi = moaApi;
        _db = db;
        _logger = logger;
    }

    /// <summary>取得所有近期產品摘要列表</summary>
    public async Task<List<ProductSummaryDto>> GetRecentProductsAsync(string? category = null)
    {
        var endDate = DateTime.Today;
        var startDate = endDate.AddDays(-7);

        var data = await _moaApi.FetchFarmTransDataAsync(startDate, endDate);

        return data
            .Where(d => d.AvgPrice > 0)
            .GroupBy(d => d.CropName)
            .Select(g => new ProductSummaryDto
            {
                CropName = g.Key,
                CropCode = g.First().CropCode,
                Category = GetCategory(g.Key),
                AvgPrice = Math.Round(g.Average(x => x.AvgPrice), 1),
                PriceLevel = DeterminePriceLevel(g.Average(x => x.AvgPrice)),
                Trend = DetermineTrend(g.OrderByDescending(x => x.TransDate).Take(3).Select(x => x.AvgPrice).ToList()),
                LastUpdated = g.OrderByDescending(x => x.TransDate).First().TransDate,
            })
            .OrderByDescending(p => p.LastUpdated)
            .ToList();
    }

    /// <summary>取得近期產品摘要列表 (含分頁元數據)</summary>
    public async Task<PaginatedResponse<ProductSummaryDto>> GetRecentProductsPaginatedAsync(string? category = null, int offset = 0, int limit = 20)
    {
        var allProducts = await GetRecentProductsAsync(category);
        var filtered = allProducts.Skip(offset).Take(limit).ToList();

        return new PaginatedResponse<ProductSummaryDto>
        {
            Data = filtered,
            Total = allProducts.Count,
            Offset = offset,
            Limit = limit,
        };
    }

    /// <summary>取得特定產品的詳情（含七日走勢、三年月均價）</summary>
    public async Task<ProductDetailDto> GetProductDetailAsync(string cropName)
    {
        // 標準化名稱
        var officialName = CropAliases.FindOfficialName(cropName) ?? cropName;

        // 七日日均價
        var endDate = DateTime.Today;
        var startDate = endDate.AddDays(-7);
        var dailyData = await _moaApi.FetchFarmTransDataAsync(startDate, endDate, officialName);

        var dailyPrices = dailyData
            .Where(d => d.AvgPrice > 0)
            .GroupBy(d => d.TransDate)
            .Select(g => new DailyPriceDto
            {
                TransDate = g.Key,
                AvgPrice = Math.Round(g.Average(x => x.AvgPrice), 1),
                UpperPrice = Math.Round(g.Max(x => x.UpperPrice), 1),
                LowerPrice = Math.Round(g.Min(x => x.LowerPrice), 1),
                Volume = Math.Round(g.Sum(x => x.Volume), 0),
            })
            .OrderBy(p => p.TransDate)
            .ToList();

        // 預測用的更長期間資料 (30天用於線性回歸)
        var predictionStartDate = endDate.AddDays(-30);
        var predictionData = await _moaApi.FetchFarmTransDataAsync(predictionStartDate, endDate, officialName);
        var dailyPricesForPrediction = predictionData
            .Where(d => d.AvgPrice > 0)
            .GroupBy(d => d.TransDate)
            .Select(g => new DailyPriceDto
            {
                TransDate = g.Key,
                AvgPrice = Math.Round(g.Average(x => x.AvgPrice), 1),
                UpperPrice = Math.Round(g.Max(x => x.UpperPrice), 1),
                LowerPrice = Math.Round(g.Min(x => x.LowerPrice), 1),
                Volume = Math.Round(g.Sum(x => x.Volume), 0),
            })
            .OrderBy(p => p.TransDate)
            .ToList();

        // 三年月均價 (從資料庫快取中聚合)
        var threeYearsAgo = endDate.AddYears(-3);
        var monthlyData = await _db.CachedDailyPrices
            .AsNoTracking()
            .Where(c => c.CropName == officialName && c.TransDate >= threeYearsAgo)
            .GroupBy(c => new { c.TransDate.Year, c.TransDate.Month })
            .Select(g => new { g.Key.Year, g.Key.Month, AvgPrice = g.Average(x => x.AvgPrice) })
            .OrderBy(m => m.Year).ThenBy(m => m.Month)
            .ToListAsync();

        var monthlyPrices = monthlyData
            .Select(m => new MonthlyPriceDto
            {
                Month = $"{m.Year}/{m.Month:D2}",
                AvgPrice = Math.Round(m.AvgPrice, 1),
            })
            .ToList();

        var currentAvgPrice = dailyPrices.Count > 0 ? dailyPrices.Last().AvgPrice : 0;

        return new ProductDetailDto
        {
            CropName = officialName,
            CropCode = dailyData.FirstOrDefault()?.CropCode ?? string.Empty,
            AvgPrice = currentAvgPrice,
            PriceLevel = DeterminePriceLevel(currentAvgPrice),
            Trend = DetermineTrend(dailyPrices.Select(p => p.AvgPrice).ToList()),
            DailyPrices = dailyPrices,
            DailyPricesForPrediction = dailyPricesForPrediction,
            MonthlyPrices = monthlyPrices,
            Aliases = CropAliases.GetAliases(officialName),
        };
    }

    /// <summary>取得所有分類清單</summary>
    public List<CategoryDto> GetCategories()
    {
        return VegetableCategories.GetCategories();
    }

    /// <summary>搜尋產品（支援別名搜尋）</summary>
    public async Task<List<ProductSummaryDto>> SearchProductsAsync(string keyword)
    {
        var allProducts = await GetRecentProductsAsync();
        var normalizedKeyword = keyword.ToLower();

        return allProducts
            .Where(p => p.CropName.ToLower().Contains(normalizedKeyword) ||
                       CropAliases.GetAliases(p.CropName).Any(a => a.ToLower().Contains(normalizedKeyword)))
            .ToList();
    }

    /// <summary>搜尋產品 (支援分頁)</summary>
    public async Task<PaginatedResponse<ProductSummaryDto>> SearchProductsPaginatedAsync(string keyword, int offset = 0, int limit = 20)
    {
        var results = await SearchProductsAsync(keyword);
        var filtered = results.Skip(offset).Take(limit).ToList();

        return new PaginatedResponse<ProductSummaryDto>
        {
            Data = filtered,
            Total = results.Count,
            Offset = offset,
            Limit = limit,
        };
    }

    private static string GetCategory(string cropName)
    {
        return VegetableCategories.GetCategory(cropName);
    }

    private static string DeterminePriceLevel(decimal avgPrice)
    {
        return avgPrice switch
        {
            > 50 => "high",
            < 20 => "low",
            _ => "normal",
        };
    }

    private static string DetermineTrend(List<decimal> prices)
    {
        if (prices.Count < 2) return "stable";

        var recentAvg = prices.TakeLast(3).Average();
        var previousAvg = prices.Count >= 6 ? prices.Skip(prices.Count - 6).Take(3).Average() : prices.First();

        var changePercent = previousAvg > 0 ? (recentAvg - previousAvg) / previousAvg * 100 : 0;

        return changePercent switch
        {
            > 5 => "up",
            < -5 => "down",
            _ => "stable",
        };
    }
}
