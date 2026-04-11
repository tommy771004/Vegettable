namespace VegettableApi.Models;

/// <summary>農業氣象觀測資料 DTO</summary>
public class WeatherObservationDto
{
    public string StationId { get; set; } = string.Empty;
    public string StationName { get; set; } = string.Empty;
    public string County { get; set; } = string.Empty;
    public string Township { get; set; } = string.Empty;
    public string ObsTime { get; set; } = string.Empty;
    /// <summary>氣溫 (°C)</summary>
    public decimal? Temperature { get; set; }
    /// <summary>相對濕度 (%)</summary>
    public decimal? RelHumidity { get; set; }
    /// <summary>累積雨量 (mm)</summary>
    public decimal? Rainfall { get; set; }
    /// <summary>風速 (m/s)</summary>
    public decimal? WindSpeed { get; set; }
    public string? WindDirection { get; set; }
    /// <summary>日照時數 (hr)</summary>
    public decimal? SunshineHours { get; set; }
    /// <summary>日射量 (MJ/m²)</summary>
    public decimal? SolarRadiation { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    /// <summary>天氣摘要：Hot / Warm / Cool / Cold / Rainy</summary>
    public string WeatherSummary { get; set; } = string.Empty;
}
