using System.Text.Json.Serialization;

namespace VegettableApi.Models;

/// <summary>
/// 農業部開放資料 — 農業氣象觀測資料原始格式 (AgrWeatherData.aspx)
/// 來源：農業部農業氣象資料中心各縣市農業氣象站
/// </summary>
public class WeatherObservationRawData
{
    [JsonPropertyName("測站代碼")]
    public string StationId { get; set; } = string.Empty;

    [JsonPropertyName("測站名稱")]
    public string StationName { get; set; } = string.Empty;

    [JsonPropertyName("縣市")]
    public string County { get; set; } = string.Empty;

    [JsonPropertyName("鄉鎮")]
    public string Township { get; set; } = string.Empty;

    [JsonPropertyName("觀測時間")]
    public string ObsTime { get; set; } = string.Empty;

    /// <summary>氣溫 (°C)</summary>
    [JsonPropertyName("氣溫")]
    public decimal? Temperature { get; set; }

    /// <summary>相對濕度 (%)</summary>
    [JsonPropertyName("相對濕度")]
    public decimal? RelHumidity { get; set; }

    /// <summary>累積雨量 (mm)</summary>
    [JsonPropertyName("累積雨量")]
    public decimal? Rainfall { get; set; }

    /// <summary>風速 (m/s)</summary>
    [JsonPropertyName("風速")]
    public decimal? WindSpeed { get; set; }

    /// <summary>風向 (度)</summary>
    [JsonPropertyName("風向")]
    public string? WindDirection { get; set; }

    /// <summary>日照時數 (hr)</summary>
    [JsonPropertyName("日照時數")]
    public decimal? SunshineHours { get; set; }

    /// <summary>日射量 (MJ/m²)</summary>
    [JsonPropertyName("日射量")]
    public decimal? SolarRadiation { get; set; }

    /// <summary>WGS84 緯度</summary>
    [JsonPropertyName("緯度")]
    public double? Latitude { get; set; }

    /// <summary>WGS84 經度</summary>
    [JsonPropertyName("經度")]
    public double? Longitude { get; set; }
}
