using VegettableApi.Models;

namespace VegettableApi.Services;

public class MarketService : IMarketService
{
    private readonly IMoaApiService _moaApi;

    // 台灣主要批發市場
    private static readonly List<MarketDto> Markets = new()
    {
        new() { MarketCode = "104", MarketName = "台北一", Region = "北部" },
        new() { MarketCode = "105", MarketName = "台北二", Region = "北部" },
        new() { MarketCode = "109", MarketName = "三重市", Region = "北部" },
        new() { MarketCode = "241", MarketName = "桃農", Region = "北部" },
        new() { MarketCode = "400", MarketName = "台中市", Region = "中部" },
        new() { MarketCode = "410", MarketName = "豐原", Region = "中部" },
        new() { MarketCode = "514", MarketName = "溪湖", Region = "中部" },
        new() { MarketCode = "648", MarketName = "西螺", Region = "中部" },
        new() { MarketCode = "800", MarketName = "高雄市", Region = "南部" },
        new() { MarketCode = "830", MarketName = "鳳山", Region = "南部" },
        new() { MarketCode = "900", MarketName = "屏東市", Region = "南部" },
        new() { MarketCode = "600", MarketName = "嘉義市", Region = "南部" },
        new() { MarketCode = "700", MarketName = "台南市", Region = "南部" },
        new() { MarketCode = "260", MarketName = "宜蘭市", Region = "東部" },
        new() { MarketCode = "970", MarketName = "花蓮市", Region = "東部" },
    };

    public MarketService(IMoaApiService moaApi)
    {
        _moaApi = moaApi;
    }

    public List<MarketDto> GetMarkets() => Markets;

    public async Task<List<MarketPriceDto>> GetMarketPricesAsync(string marketName, string? cropName = null)
    {
        var endDate = DateTime.Today;
        var startDate = endDate.AddDays(-7);

        var data = await _moaApi.FetchFarmTransDataAsync(startDate, endDate, cropName: cropName, market: marketName);

        return data
            .Where(d => d.AvgPrice > 0)
            .GroupBy(d => new { d.CropName, d.TransDate })
            .Select(g => new MarketPriceDto
            {
                MarketName = marketName,
                CropName = g.Key.CropName,
                AvgPrice = Math.Round(g.Average(x => x.AvgPrice), 1),
                UpperPrice = Math.Round(g.Max(x => x.UpperPrice), 1),
                LowerPrice = Math.Round(g.Min(x => x.LowerPrice), 1),
                Volume = Math.Round(g.Sum(x => x.Volume), 0),
                TransDate = g.Key.TransDate,
            })
            .OrderByDescending(d => d.TransDate)
            .ToList();
    }

    public async Task<List<MarketPriceDto>> CompareMarketPricesAsync(string cropName, List<string>? markets = null)
    {
        var targetMarkets = markets ?? Markets.Select(m => m.MarketName).Take(5).ToList();
        var endDate = DateTime.Today;
        var startDate = endDate.AddDays(-3);

        var tasks = targetMarkets.Select(market =>
            _moaApi.FetchFarmTransDataAsync(startDate, endDate, cropName: cropName, market: market));

        var results = await Task.WhenAll(tasks);
        var allData = results.SelectMany(r => r).Where(d => d.AvgPrice > 0).ToList();

        return allData
            .GroupBy(d => d.MarketName)
            .Select(g => new MarketPriceDto
            {
                MarketName = g.Key,
                CropName = cropName,
                AvgPrice = Math.Round(g.Average(x => x.AvgPrice), 1),
                UpperPrice = Math.Round(g.Max(x => x.UpperPrice), 1),
                LowerPrice = Math.Round(g.Min(x => x.LowerPrice), 1),
                Volume = Math.Round(g.Sum(x => x.Volume), 0),
                TransDate = g.OrderByDescending(x => x.TransDate).First().TransDate,
            })
            .OrderBy(d => d.AvgPrice)
            .ToList();
    }
}
