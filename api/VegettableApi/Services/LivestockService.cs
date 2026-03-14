using VegettableApi.Models;

namespace VegettableApi.Services;

/// <summary>
/// 畜產品行情服務 — 整合農業部 LivestockTransData API
/// </summary>
public class LivestockService : ILivestockService
{
    private readonly IMoaApiService _moaApi;
    private readonly IConfiguration _config;

    public LivestockService(IMoaApiService moaApi, IConfiguration config)
    {
        _moaApi = moaApi;
        _config = config;
    }

    public async Task<List<LivestockPriceDto>> GetRecentLivestockPricesAsync(string? livestockName = null)
    {
        var days = _config.GetValue("ApiSettings:Market:DefaultQueryDays", 7);
        var endDate = DateTime.Today;
        var startDate = endDate.AddDays(-days);

        var data = await _moaApi.FetchLivestockTransDataAsync(startDate, endDate, livestockName);

        return data
            .Where(d => d.AvgPrice > 0)
            .GroupBy(d => new { d.LivestockName, d.MarketName })
            .Select(g =>
            {
                var items = g.OrderBy(x => x.TransDate).ToList();
                return new LivestockPriceDto
                {
                    LivestockCode = g.First().LivestockCode,
                    LivestockName = g.Key.LivestockName,
                    MarketName    = g.Key.MarketName,
                    AvgPrice      = Math.Round(g.Average(x => x.AvgPrice), 1),
                    UpperPrice    = Math.Round(g.Max(x => x.UpperPrice), 1),
                    LowerPrice    = Math.Round(g.Min(x => x.LowerPrice), 1),
                    HeadCount     = g.Sum(x => x.HeadCount),
                    AvgWeight     = Math.Round(g.Average(x => x.AvgWeight), 1),
                    TransDate     = g.OrderByDescending(x => x.TransDate).First().TransDate,
                    Trend         = CalcTrend(items.Select(x => x.AvgPrice).ToList()),
                };
            })
            .OrderByDescending(d => d.HeadCount)
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
