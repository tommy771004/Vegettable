using VegettableApi.Models;

namespace VegettableApi.Services;

/// <summary>
/// 毛豬行情服務 — 整合農業部 AnimalTransData API (肉品市場)
/// </summary>
public class AnimalService : IAnimalService
{
    private readonly IMoaApiService _moaApi;
    private readonly IConfiguration _config;
    private readonly ILogger<AnimalService> _logger;

    public AnimalService(IMoaApiService moaApi, IConfiguration config, ILogger<AnimalService> logger)
    {
        _moaApi = moaApi;
        _config = config;
        _logger = logger;
    }

    public async Task<List<AnimalPriceDto>> GetRecentAnimalPricesAsync(
        string? productName = null, string? market = null)
    {
        var days = _config.GetValue("ApiSettings:Market:DefaultQueryDays", 7);
        var endDate = DateTime.Today;
        var startDate = endDate.AddDays(-days);

        var data = await _moaApi.FetchAnimalTransDataAsync(startDate, endDate, productName, market);

        return data
            .Where(d => d.AvgPrice > 0)
            .GroupBy(d => new { d.ProductName, d.MarketName })
            .Select(g =>
            {
                var items = g.OrderBy(x => x.TransDate).ToList();
                return new AnimalPriceDto
                {
                    ProductCode = g.First().ProductCode,
                    ProductName = g.Key.ProductName,
                    MarketName  = g.Key.MarketName,
                    AvgPrice    = Math.Round(g.Average(x => x.AvgPrice), 1),
                    UpperPrice  = Math.Round(g.Max(x => x.UpperPrice), 1),
                    LowerPrice  = Math.Round(g.Min(x => x.LowerPrice), 1),
                    HeadCount   = g.Sum(x => x.HeadCount),
                    AvgWeight   = Math.Round(g.Average(x => x.AvgWeight), 1),
                    TransDate   = g.OrderByDescending(x => x.TransDate).First().TransDate,
                    Trend       = CalcTrend(items.Select(x => x.AvgPrice).ToList()),
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
