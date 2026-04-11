using VegettableApi.Models;
using Microsoft.Extensions.Caching.Memory;

namespace VegettableApi.Services;

/// <summary>
/// 農業氣象服務 — 整合農業部 AgrWeatherData API
/// 資料來源：data.moa.gov.tw 農業氣象觀測站
/// </summary>
public class AgrWeatherService : IAgrWeatherService
{
    private readonly IMoaApiService _moaApi;
    private readonly IMemoryCache _cache;
    private readonly ILogger<AgrWeatherService> _logger;

    private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(30);

    public AgrWeatherService(
        IMoaApiService moaApi,
        IMemoryCache cache,
        ILogger<AgrWeatherService> logger)
    {
        _moaApi = moaApi;
        _cache = cache;
        _logger = logger;
    }

    public async Task<List<WeatherObservationDto>> GetLatestObservationsAsync(string? county = null)
    {
        var cacheKey = $"weather_latest_{county ?? "all"}";

        return await _cache.GetOrCreateAsync(cacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = CacheDuration;
            entry.Size = 1;

            var raw = await _moaApi.FetchAgrWeatherDataAsync(county: county, top: 500);

            // 每個測站只取最新一筆
            var latest = raw
                .GroupBy(r => r.StationId)
                .Select(g => g.OrderByDescending(x => x.ObsTime).First())
                .ToList();

            return latest.Select(ToDto).ToList();
        }) ?? new List<WeatherObservationDto>();
    }

    public async Task<List<WeatherObservationDto>> GetStationObservationsAsync(string stationId, int days = 7)
    {
        var cacheKey = $"weather_station_{stationId}_{days}d";

        return await _cache.GetOrCreateAsync(cacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(15);
            entry.Size = 1;

            var endDate = DateTime.Today;
            var startDate = endDate.AddDays(-days);

            var raw = await _moaApi.FetchAgrWeatherDataAsync(
                startDate, endDate, stationId: stationId, top: 1000);

            return raw
                .OrderByDescending(x => x.ObsTime)
                .Select(ToDto)
                .ToList();
        }) ?? new List<WeatherObservationDto>();
    }

    private static WeatherObservationDto ToDto(WeatherObservationRawData r) => new()
    {
        StationId      = r.StationId,
        StationName    = r.StationName,
        County         = r.County,
        Township       = r.Township,
        ObsTime        = r.ObsTime,
        Temperature    = r.Temperature,
        RelHumidity    = r.RelHumidity,
        Rainfall       = r.Rainfall,
        WindSpeed      = r.WindSpeed,
        WindDirection  = r.WindDirection,
        SunshineHours  = r.SunshineHours,
        SolarRadiation = r.SolarRadiation,
        Latitude       = r.Latitude,
        Longitude      = r.Longitude,
        WeatherSummary = CalcSummary(r.Temperature, r.Rainfall),
    };

    private static string CalcSummary(decimal? temp, decimal? rain)
    {
        if (rain is > 5m) return "Rainy";
        return temp switch
        {
            > 30m => "Hot",
            > 22m => "Warm",
            > 15m => "Cool",
            not null => "Cold",
            _ => "Unknown",
        };
    }
}
