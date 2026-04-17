using System.Collections.Concurrent;
using System.Text.Json;
using Microsoft.Extensions.Caching.Memory;
using VegettableApi.Models;

namespace VegettableApi.Services;

/// <summary>
/// 農業部開放資料 API 服務實作
/// 支援：蔬果、漁產、畜產、有機/產銷履歷行情
/// 快取策略：IMemoryCache + 請求去重（ConcurrentDictionary）
/// </summary>
public class MoaApiService : IMoaApiService
{
    private readonly HttpClient _httpClient;
    private readonly IMemoryCache _cache;
    private readonly ILogger<MoaApiService> _logger;
    private readonly IConfiguration _config;

    private const string FarmTransEndpoint     = "Service/OpenData/FromM/FarmTransData.aspx";
    private const string AquaticTransEndpoint  = "Service/OpenData/FromM/AquaticTransData.aspx";
    private const string LivestockTransEndpoint = "Service/OpenData/FromM/LivestockTransData.aspx";
    private const string OrganicTransEndpoint  = "Service/OpenData/FromM/TAPData.aspx";
    private const string FlowerTransEndpoint   = "Service/OpenData/FromM/FlowerData.aspx";
    private const string AnimalTransEndpoint   = "Service/OpenData/FromM/AnimalTransData.aspx";
    private const string AgrWeatherEndpoint    = "Service/OpenData/FromM/AgrWeatherData.aspx";

    private static readonly ConcurrentDictionary<string, Task<string>> _inflightRequests = new();

    public MoaApiService(HttpClient httpClient, IMemoryCache cache, ILogger<MoaApiService> logger, IConfiguration config)
    {
        _httpClient = httpClient;
        _cache = cache;
        _logger = logger;
        _config = config;
    }

    // ─── 蔬果行情 ──────────────────────────────────────────────

    public async Task<List<MoaRawData>> FetchFarmTransDataAsync(
        DateTime? startDate = null, DateTime? endDate = null,
        string? cropName = null, string? market = null,
        int top = 20000, int skip = 0)
    {
        var cacheMinutes = _config.GetValue("ApiSettings:Cache:FarmTransMinutes", 10);
        var cacheKey = $"moa_farm_{startDate:yyyyMMdd}_{endDate:yyyyMMdd}_{cropName}_{market}_{top}_{skip}";

        if (_cache.TryGetValue(cacheKey, out List<MoaRawData>? cached) && cached is not null)
            return cached;

        var queryParams = BuildBaseParams(top, skip, startDate, endDate);
        if (!string.IsNullOrWhiteSpace(cropName)) queryParams.Add($"CropName={Uri.EscapeDataString(cropName)}");
        if (!string.IsNullOrWhiteSpace(market))   queryParams.Add($"Market={Uri.EscapeDataString(market)}");

        var json = await FetchJsonAsync(FarmTransEndpoint, queryParams, cacheKey);
        var data = Deserialize<MoaRawData>(json);
        CacheResult(cacheKey, data, cacheMinutes);
        return data;
    }

    // ─── 漁產行情 ──────────────────────────────────────────────

    public async Task<List<AquaticRawData>> FetchAquaticTransDataAsync(
        DateTime? startDate = null, DateTime? endDate = null,
        string? fishName = null, string? market = null,
        int top = 10000)
    {
        var cacheMinutes = _config.GetValue("ApiSettings:Cache:FishMinutes", 10);
        var cacheKey = $"moa_fish_{startDate:yyyyMMdd}_{endDate:yyyyMMdd}_{fishName}_{market}_{top}";

        if (_cache.TryGetValue(cacheKey, out List<AquaticRawData>? cached) && cached is not null)
            return cached;

        var queryParams = BuildBaseParams(top, 0, startDate, endDate);
        if (!string.IsNullOrWhiteSpace(fishName)) queryParams.Add($"FishName={Uri.EscapeDataString(fishName)}");
        if (!string.IsNullOrWhiteSpace(market))   queryParams.Add($"Market={Uri.EscapeDataString(market)}");

        var json = await FetchJsonAsync(AquaticTransEndpoint, queryParams, cacheKey);
        var data = Deserialize<AquaticRawData>(json);
        CacheResult(cacheKey, data, cacheMinutes);
        return data;
    }

    // ─── 畜產行情 ──────────────────────────────────────────────

    public async Task<List<LivestockRawData>> FetchLivestockTransDataAsync(
        DateTime? startDate = null, DateTime? endDate = null,
        string? livestockName = null, int top = 10000)
    {
        var cacheMinutes = _config.GetValue("ApiSettings:Cache:LivestockMinutes", 10);
        var cacheKey = $"moa_livestock_{startDate:yyyyMMdd}_{endDate:yyyyMMdd}_{livestockName}_{top}";

        if (_cache.TryGetValue(cacheKey, out List<LivestockRawData>? cached) && cached is not null)
            return cached;

        var queryParams = BuildBaseParams(top, 0, startDate, endDate);
        if (!string.IsNullOrWhiteSpace(livestockName)) queryParams.Add($"LivestockName={Uri.EscapeDataString(livestockName)}");

        var json = await FetchJsonAsync(LivestockTransEndpoint, queryParams, cacheKey);
        var data = Deserialize<LivestockRawData>(json);
        CacheResult(cacheKey, data, cacheMinutes);
        return data;
    }

    // ─── 有機/產銷履歷行情 ─────────────────────────────────────

    public async Task<List<OrganicRawData>> FetchOrganicTransDataAsync(
        DateTime? startDate = null, DateTime? endDate = null,
        string? cropName = null, int top = 10000)
    {
        var cacheMinutes = _config.GetValue("ApiSettings:Cache:OrganicMinutes", 30);
        var cacheKey = $"moa_organic_{startDate:yyyyMMdd}_{endDate:yyyyMMdd}_{cropName}_{top}";

        if (_cache.TryGetValue(cacheKey, out List<OrganicRawData>? cached) && cached is not null)
            return cached;

        var queryParams = BuildBaseParams(top, 0, startDate, endDate);
        if (!string.IsNullOrWhiteSpace(cropName)) queryParams.Add($"CropName={Uri.EscapeDataString(cropName)}");

        var json = await FetchJsonAsync(OrganicTransEndpoint, queryParams, cacheKey);
        var data = Deserialize<OrganicRawData>(json);
        CacheResult(cacheKey, data, cacheMinutes);
        return data;
    }

    // ─── 花卉行情 ──────────────────────────────────────────────

    public async Task<List<FlowerRawData>> FetchFlowerTransDataAsync(
        DateTime? startDate = null, DateTime? endDate = null,
        string? flowerName = null, string? market = null,
        int top = 10000)
    {
        var cacheMinutes = _config.GetValue("ApiSettings:Cache:FlowerMinutes", 10);
        var cacheKey = $"moa_flower_{startDate:yyyyMMdd}_{endDate:yyyyMMdd}_{flowerName}_{market}_{top}";

        if (_cache.TryGetValue(cacheKey, out List<FlowerRawData>? cached) && cached is not null)
            return cached;

        var queryParams = BuildBaseParams(top, 0, startDate, endDate);
        if (!string.IsNullOrWhiteSpace(flowerName)) queryParams.Add($"FlowerName={Uri.EscapeDataString(flowerName)}");
        if (!string.IsNullOrWhiteSpace(market))     queryParams.Add($"Market={Uri.EscapeDataString(market)}");

        var json = await FetchJsonAsync(FlowerTransEndpoint, queryParams, cacheKey);
        var data = Deserialize<FlowerRawData>(json);
        CacheResult(cacheKey, data, cacheMinutes);
        return data;
    }

    // ─── 毛豬行情 ──────────────────────────────────────────────

    public async Task<List<AnimalRawData>> FetchAnimalTransDataAsync(
        DateTime? startDate = null, DateTime? endDate = null,
        string? productName = null, string? market = null,
        int top = 10000)
    {
        var cacheMinutes = _config.GetValue("ApiSettings:Cache:AnimalMinutes", 10);
        var cacheKey = $"moa_animal_{startDate:yyyyMMdd}_{endDate:yyyyMMdd}_{productName}_{market}_{top}";

        if (_cache.TryGetValue(cacheKey, out List<AnimalRawData>? cached) && cached is not null)
            return cached;

        var queryParams = BuildBaseParams(top, 0, startDate, endDate);
        if (!string.IsNullOrWhiteSpace(productName)) queryParams.Add($"ProductName={Uri.EscapeDataString(productName)}");
        if (!string.IsNullOrWhiteSpace(market))      queryParams.Add($"Market={Uri.EscapeDataString(market)}");

        var json = await FetchJsonAsync(AnimalTransEndpoint, queryParams, cacheKey);
        var data = Deserialize<AnimalRawData>(json);
        CacheResult(cacheKey, data, cacheMinutes);
        return data;
    }

    // ─── 農業氣象 ──────────────────────────────────────────────

    public async Task<List<WeatherObservationRawData>> FetchAgrWeatherDataAsync(
        DateTime? startDate = null, DateTime? endDate = null,
        string? stationId = null, string? county = null,
        int top = 1000)
    {
        var cacheMinutes = _config.GetValue("ApiSettings:Cache:WeatherMinutes", 30);
        var cacheKey = $"moa_weather_{startDate:yyyyMMdd}_{endDate:yyyyMMdd}_{stationId}_{county}_{top}";

        if (_cache.TryGetValue(cacheKey, out List<WeatherObservationRawData>? cached) && cached is not null)
            return cached;

        var queryParams = BuildBaseParams(top, 0, startDate, endDate);
        if (!string.IsNullOrWhiteSpace(stationId)) queryParams.Add($"StationId={Uri.EscapeDataString(stationId)}");
        if (!string.IsNullOrWhiteSpace(county))    queryParams.Add($"County={Uri.EscapeDataString(county)}");

        var json = await FetchJsonAsync(AgrWeatherEndpoint, queryParams, cacheKey);
        var data = Deserialize<WeatherObservationRawData>(json);
        CacheResult(cacheKey, data, cacheMinutes);
        return data;
    }

    // ─── 共用方法 ──────────────────────────────────────────────

    private List<string> BuildBaseParams(int top, int skip, DateTime? startDate, DateTime? endDate)
    {
        var p = new List<string> { $"$top={top}" };
        if (skip > 0)              p.Add($"$skip={skip}");
        if (startDate.HasValue)    p.Add($"StartDate={ToRocDate(startDate.Value)}");
        if (endDate.HasValue)      p.Add($"EndDate={ToRocDate(endDate.Value)}");
        return p;
    }

    private async Task<string> FetchJsonAsync(string endpoint, List<string> queryParams, string cacheKey)
    {
        var url = $"{endpoint}?{string.Join("&", queryParams)}";
        _logger.LogInformation("Fetching MOA: {Url}", url);

        // 請求去重 — 相同 key 只發一次 HTTP
        return await _inflightRequests.GetOrAdd(cacheKey, async _key =>
        {
            try
            {
                using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(30));
                var response = await _httpClient.GetAsync(url, cts.Token);
                response.EnsureSuccessStatusCode();
                return await response.Content.ReadAsStringAsync(cts.Token);
            }
            catch (TaskCanceledException ex)
            {
                _logger.LogWarning(ex, "MOA request timed out: {Endpoint}", endpoint);
                return string.Empty;
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "HTTP error fetching MOA endpoint: {Endpoint}", endpoint);
                return string.Empty;
            }
            finally
            {
                _inflightRequests.TryRemove(cacheKey, out _);
            }
        });
    }

    private List<T> Deserialize<T>(string json)
    {
        if (string.IsNullOrWhiteSpace(json)) return new List<T>();
        try
        {
            return JsonSerializer.Deserialize<List<T>>(json) ?? new List<T>();
        }
        catch (JsonException ex)
        {
            var preview = json.Length > 200 ? json[..200] + "..." : json;
            _logger.LogError(ex, "JSON parse failed for {Type}. Preview: {Preview}", typeof(T).Name, preview);
            return new List<T>();
        }
    }

    private void CacheResult<T>(string key, List<T> data, int minutes)
    {
        // 空結果使用較短 TTL（1 分鐘），避免因暫時性錯誤長時間回傳空資料
        var ttl = data.Count == 0 ? Math.Min(1, minutes) : minutes;
        _cache.Set(key, data, new MemoryCacheEntryOptions()
            .SetAbsoluteExpiration(TimeSpan.FromMinutes(ttl))
            .SetSize(1));
        _logger.LogInformation("Cached {Count} records, key={Key}, ttl={Ttl}m", data.Count, key, ttl);
    }

    /// <summary>西元年轉民國年 (YYY.MM.DD)</summary>
    private static string ToRocDate(DateTime date)
    {
        if (date.Year < 1912)
            throw new ArgumentException($"Date {date:yyyy-MM-dd} is before ROC era (1912)", nameof(date));
        return $"{date.Year - 1911}.{date.Month:D2}.{date.Day:D2}";
    }
}
