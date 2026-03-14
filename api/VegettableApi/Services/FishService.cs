using VegettableApi.Models;

namespace VegettableApi.Services;

/// <summary>
/// 漁產品行情服務 — 整合農業部 AquaticTransData API
/// </summary>
public class FishService : IFishService
{
    private readonly IMoaApiService _moaApi;
    private readonly IConfiguration _config;
    private readonly ILogger<FishService> _logger;

    public FishService(IMoaApiService moaApi, IConfiguration config, ILogger<FishService> logger)
    {
        _moaApi = moaApi;
        _config = config;
        _logger = logger;
    }

    public async Task<List<AquaticPriceDto>> GetRecentFishPricesAsync(string? fishName = null, string? market = null)
    {
        var days = _config.GetValue("ApiSettings:Market:DefaultQueryDays", 7);
        var endDate = DateTime.Today;
        var startDate = endDate.AddDays(-days);

        var data = await _moaApi.FetchAquaticTransDataAsync(startDate, endDate, fishName, market);

        return data
            .Where(d => d.AvgPrice > 0)
            .GroupBy(d => new { d.FishName, d.MarketName })
            .Select(g =>
            {
                var items = g.OrderBy(x => x.TransDate).ToList();
                return new AquaticPriceDto
                {
                    FishCode    = g.First().FishCode,
                    FishName    = g.Key.FishName,
                    MarketName  = g.Key.MarketName,
                    AvgPrice    = Math.Round(g.Average(x => x.AvgPrice), 1),
                    UpperPrice  = Math.Round(g.Max(x => x.UpperPrice), 1),
                    LowerPrice  = Math.Round(g.Min(x => x.LowerPrice), 1),
                    Volume      = Math.Round(g.Sum(x => x.Volume), 0),
                    TransDate   = g.OrderByDescending(x => x.TransDate).First().TransDate,
                    Trend       = CalcTrend(items.Select(x => x.AvgPrice).ToList()),
                };
            })
            .OrderByDescending(d => d.Volume)
            .ToList();
    }

    public async Task<List<AquaticPriceDto>> GetFishPricesByMarketAsync(string marketName, string? fishName = null)
    {
        var days = _config.GetValue("ApiSettings:Market:DefaultQueryDays", 7);
        var endDate = DateTime.Today;
        var startDate = endDate.AddDays(-days);

        var data = await _moaApi.FetchAquaticTransDataAsync(startDate, endDate, fishName, marketName);

        return data
            .Where(d => d.AvgPrice > 0)
            .GroupBy(d => new { d.FishName, d.TransDate })
            .Select(g => new AquaticPriceDto
            {
                FishCode   = g.First().FishCode,
                FishName   = g.Key.FishName,
                MarketName = marketName,
                AvgPrice   = Math.Round(g.Average(x => x.AvgPrice), 1),
                UpperPrice = Math.Round(g.Max(x => x.UpperPrice), 1),
                LowerPrice = Math.Round(g.Min(x => x.LowerPrice), 1),
                Volume     = Math.Round(g.Sum(x => x.Volume), 0),
                TransDate  = g.Key.TransDate,
                Trend      = "stable",
            })
            .OrderByDescending(d => d.TransDate)
            .ThenByDescending(d => d.Volume)
            .ToList();
    }

    private static string CalcTrend(List<decimal> prices)
    {
        if (prices.Count < 2) return "stable";
        var first = prices.First();
        var last  = prices.Last();
        if (first <= 0) return "stable";
        var change = (last - first) / first;
        return change switch { > 0.03m => "up", < -0.03m => "down", _ => "stable" };
    }
}
