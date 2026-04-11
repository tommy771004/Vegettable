using VegettableApi.Models;

namespace VegettableApi.Services;

public interface IAgrWeatherService
{
    /// <summary>取得各縣市農業氣象站最新觀測資料</summary>
    Task<List<WeatherObservationDto>> GetLatestObservationsAsync(string? county = null);

    /// <summary>取得指定測站近期觀測記錄</summary>
    Task<List<WeatherObservationDto>> GetStationObservationsAsync(string stationId, int days = 7);
}
