using VegettableApi.Models;

namespace VegettableApi.Services;

/// <summary>
/// 有機/產銷履歷蔬果行情服務 — 整合農業部 TAPData API
/// 額外計算有機溢價（與一般批發價比較）
/// </summary>
public class OrganicService : IOrganicService
{
    private readonly IMoaApiService _moaApi;
    private readonly IProductService _productService;
    private readonly IConfiguration _config;

    public OrganicService(IMoaApiService moaApi, IProductService productService, IConfiguration config)
    {
        _moaApi = moaApi;
        _productService = productService;
        _config = config;
    }

    public async Task<List<OrganicPriceDto>> GetRecentOrganicPricesAsync(string? cropName = null, string? certType = null)
    {
        var days = _config.GetValue("ApiSettings:Market:DefaultQueryDays", 7);
        var endDate = DateTime.Today;
        var startDate = endDate.AddDays(-days);

        // 並行取得有機行情 + 一般批發行情（用於計算溢價）
        var organicTask   = _moaApi.FetchOrganicTransDataAsync(startDate, endDate, cropName);
        var regularTask   = _productService.GetRecentProductsAsync();
        await Task.WhenAll(organicTask, regularTask);

        var organicData = await organicTask;
        var regularData = await regularTask;

        // 建立一般批發均價 Map（作物名稱 → 均價）
        var regularPriceMap = regularData
            .Where(p => p.AvgPrice > 0)
            .ToDictionary(p => p.CropName, p => p.AvgPrice);

        return organicData
            .Where(d => d.AvgPrice > 0)
            .Where(d => string.IsNullOrWhiteSpace(certType) || d.CertType == certType)
            .GroupBy(d => new { d.CropName, d.CertType, d.MarketName })
            .Select(g =>
            {
                var avgPrice = Math.Round(g.Average(x => x.AvgPrice), 1);
                decimal? premium = null;
                if (regularPriceMap.TryGetValue(g.Key.CropName, out var regular) && regular > 0)
                    premium = Math.Round((avgPrice - regular) / regular * 100, 1);

                return new OrganicPriceDto
                {
                    CropCode       = g.First().CropCode,
                    CropName       = g.Key.CropName,
                    MarketName     = g.Key.MarketName,
                    AvgPrice       = avgPrice,
                    UpperPrice     = Math.Round(g.Max(x => x.UpperPrice), 1),
                    LowerPrice     = Math.Round(g.Min(x => x.LowerPrice), 1),
                    Volume         = Math.Round(g.Sum(x => x.Volume), 0),
                    CertType       = g.Key.CertType,
                    TransDate      = g.OrderByDescending(x => x.TransDate).First().TransDate,
                    PremiumPercent = premium,
                };
            })
            .OrderByDescending(d => d.Volume)
            .ToList();
    }
}
