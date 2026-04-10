using VegettableApi.Models;

namespace VegettableApi.Services;

public class MarketService : IMarketService
{
    private readonly IMoaApiService _moaApi;

    // 台灣主要批發市場（含地址與 GPS 座標）
    private static readonly List<MarketDto> Markets = new()
    {
        new() { MarketCode = "104", MarketName = "台北一",  Region = "北部", Address = "台北市萬華區萬大路533號",          Latitude = 25.0258, Longitude = 121.5010 },
        new() { MarketCode = "105", MarketName = "台北二",  Region = "北部", Address = "台北市中山區民族東路336號",        Latitude = 25.0690, Longitude = 121.5375 },
        new() { MarketCode = "109", MarketName = "三重",    Region = "北部", Address = "新北市三重區大同北路107號",        Latitude = 25.0620, Longitude = 121.4872 },
        new() { MarketCode = "241", MarketName = "桃園",    Region = "北部", Address = "桃園市桃園區中山路590號",          Latitude = 24.9917, Longitude = 121.3125 },
        new() { MarketCode = "400", MarketName = "台中",    Region = "中部", Address = "台中市西屯區中清路350號",          Latitude = 24.1795, Longitude = 120.6547 },
        new() { MarketCode = "410", MarketName = "豐原",    Region = "中部", Address = "台中市豐原區中山路389號",          Latitude = 24.2525, Longitude = 120.7180 },
        new() { MarketCode = "514", MarketName = "溪湖",    Region = "中部", Address = "彰化縣溪湖鎮彰水路四段510號",     Latitude = 23.9617, Longitude = 120.4793 },
        new() { MarketCode = "648", MarketName = "西螺",    Region = "中部", Address = "雲林縣西螺鎮九隆里延平路248號",   Latitude = 23.7983, Longitude = 120.4602 },
        new() { MarketCode = "600", MarketName = "嘉義",    Region = "南部", Address = "嘉義市西區博愛路二段459號",        Latitude = 23.4817, Longitude = 120.4343 },
        new() { MarketCode = "700", MarketName = "台南",    Region = "南部", Address = "台南市北區忠北街7號",              Latitude = 23.0125, Longitude = 120.2153 },
        new() { MarketCode = "800", MarketName = "高雄",    Region = "南部", Address = "高雄市三民區建國三路192號",        Latitude = 22.6440, Longitude = 120.3120 },
        new() { MarketCode = "830", MarketName = "鳳山",    Region = "南部", Address = "高雄市鳳山區建國路三段39號",       Latitude = 22.6273, Longitude = 120.3419 },
        new() { MarketCode = "900", MarketName = "屏東",    Region = "南部", Address = "屏東縣屏東市工業路9號",            Latitude = 22.6656, Longitude = 120.4950 },
        new() { MarketCode = "260", MarketName = "宜蘭",    Region = "東部", Address = "宜蘭縣宜蘭市環市東路二段1號",     Latitude = 24.7469, Longitude = 121.7515 },
        new() { MarketCode = "970", MarketName = "花蓮",    Region = "東部", Address = "花蓮縣花蓮市中華路100號",          Latitude = 23.9872, Longitude = 121.6044 },
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
