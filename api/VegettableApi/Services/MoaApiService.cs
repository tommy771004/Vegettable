using System.Text.Json;
using Microsoft.Extensions.Caching.Memory;
using VegettableApi.Models;

namespace VegettableApi.Services;

/// <summary>
/// 農業部開放資料 API 服務實作
/// 負責呼叫 data.moa.gov.tw 取得農產品交易行情
/// </summary>
public class MoaApiService : IMoaApiService
{
    private readonly HttpClient _httpClient;
    private readonly IMemoryCache _cache;
    private readonly ILogger<MoaApiService> _logger;

    private const string FarmTransEndpoint = "Service/OpenData/FromM/FarmTransData.aspx";

    public MoaApiService(HttpClient httpClient, IMemoryCache cache, ILogger<MoaApiService> logger)
    {
        _httpClient = httpClient;
        _cache = cache;
        _logger = logger;
    }

    public async Task<List<MoaRawData>> FetchFarmTransDataAsync(
        DateTime? startDate = null,
        DateTime? endDate = null,
        string? cropName = null,
        string? market = null,
        int top = 20000,
        int skip = 0)
    {
        // 組合快取 key
        var cacheKey = $"moa_farm_{startDate:yyyyMMdd}_{endDate:yyyyMMdd}_{cropName}_{market}_{top}_{skip}";

        if (_cache.TryGetValue(cacheKey, out List<MoaRawData>? cached) && cached is not null)
        {
            _logger.LogDebug("Cache hit: {CacheKey}", cacheKey);
            return cached;
        }

        var queryParams = new List<string> { $"$top={top}" };

        if (skip > 0) queryParams.Add($"$skip={skip}");
        if (startDate.HasValue) queryParams.Add($"StartDate={ToRocDate(startDate.Value)}");
        if (endDate.HasValue) queryParams.Add($"EndDate={ToRocDate(endDate.Value)}");
        if (!string.IsNullOrWhiteSpace(cropName)) queryParams.Add($"CropName={Uri.EscapeDataString(cropName)}");
        if (!string.IsNullOrWhiteSpace(market)) queryParams.Add($"Market={Uri.EscapeDataString(market)}");

        var url = $"{FarmTransEndpoint}?{string.Join("&", queryParams)}";

        _logger.LogInformation("Fetching MOA data: {Url}", url);

        var response = await _httpClient.GetAsync(url);
        response.EnsureSuccessStatusCode();

        var json = await response.Content.ReadAsStringAsync();

        var data = JsonSerializer.Deserialize<List<MoaRawData>>(json) ?? new List<MoaRawData>();

        // 快取 10 分鐘 (交易行情不需即時)
        var cacheOptions = new MemoryCacheEntryOptions()
            .SetAbsoluteExpiration(TimeSpan.FromMinutes(10))
            .SetSize(1);

        _cache.Set(cacheKey, data, cacheOptions);

        _logger.LogInformation("Fetched {Count} records from MOA API", data.Count);
        return data;
    }

    /// <summary>
    /// 西元年轉民國年日期格式 (YYY.MM.DD)
    /// </summary>
    private static string ToRocDate(DateTime date)
    {
        int rocYear = date.Year - 1911;
        return $"{rocYear}.{date.Month:D2}.{date.Day:D2}";
    }
}
