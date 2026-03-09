using System.Collections.Concurrent;
using System.Text.Json;
using Microsoft.Extensions.Caching.Memory;
using VegettableApi.Models;

namespace VegettableApi.Services;

/// <summary>
/// 農業部開放資料 API 服務實作
/// 負責呼叫 data.moa.gov.tw 取得農產品交易行情
/// 快取策略：目前使用 IMemoryCache（可替換為 IDistributedCache/Redis）
/// </summary>
public class MoaApiService : IMoaApiService
{
    private readonly HttpClient _httpClient;
    private readonly IMemoryCache _cache;
    private readonly ILogger<MoaApiService> _logger;

    private const string FarmTransEndpoint = "Service/OpenData/FromM/FarmTransData.aspx";

    /// <summary>
    /// 請求去重：相同 cacheKey 的並行請求只會發出一次 HTTP 呼叫
    /// </summary>
    private static readonly ConcurrentDictionary<string, Task<List<MoaRawData>>> _inflightRequests = new();

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

        // 請求去重 — 相同 key 的並行請求共用同一個 Task
        return await _inflightRequests.GetOrAdd(cacheKey, _ => FetchAndCacheAsync(cacheKey, startDate, endDate, cropName, market, top, skip));
    }

    private async Task<List<MoaRawData>> FetchAndCacheAsync(
        string cacheKey, DateTime? startDate, DateTime? endDate,
        string? cropName, string? market, int top, int skip)
    {
        try
        {
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
        finally
        {
            _inflightRequests.TryRemove(cacheKey, out _);
        }
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
