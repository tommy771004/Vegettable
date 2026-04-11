using System.Text.Json.Serialization;

namespace VegettableApi.Models;

/// <summary>
/// 農業部開放資料 — 花卉交易行情原始資料 (FlowerData.aspx)
/// </summary>
public class FlowerRawData
{
    [JsonPropertyName("交易日期")]
    public string TransDate { get; set; } = string.Empty;

    [JsonPropertyName("花卉代號")]
    public string FlowerCode { get; set; } = string.Empty;

    [JsonPropertyName("花卉名稱")]
    public string FlowerName { get; set; } = string.Empty;

    [JsonPropertyName("花卉種類")]
    public string FlowerType { get; set; } = string.Empty;

    [JsonPropertyName("市場代號")]
    public string MarketCode { get; set; } = string.Empty;

    [JsonPropertyName("市場名稱")]
    public string MarketName { get; set; } = string.Empty;

    [JsonPropertyName("上價")]
    public decimal UpperPrice { get; set; }

    [JsonPropertyName("中價")]
    public decimal MidPrice { get; set; }

    [JsonPropertyName("下價")]
    public decimal LowerPrice { get; set; }

    [JsonPropertyName("平均價")]
    public decimal AvgPrice { get; set; }

    [JsonPropertyName("交易量")]
    public decimal Volume { get; set; }
}
