using System.Text.Json.Serialization;

namespace VegettableApi.Models;

/// <summary>
/// 農業部開放資料 — 畜產品交易行情原始資料 (LivestockTransData.aspx)
/// </summary>
public class LivestockRawData
{
    [JsonPropertyName("交易日期")]
    public string TransDate { get; set; } = string.Empty;

    [JsonPropertyName("牲畜代號")]
    public string LivestockCode { get; set; } = string.Empty;

    [JsonPropertyName("牲畜名稱")]
    public string LivestockName { get; set; } = string.Empty;

    [JsonPropertyName("市場代號")]
    public string MarketCode { get; set; } = string.Empty;

    [JsonPropertyName("市場名稱")]
    public string MarketName { get; set; } = string.Empty;

    [JsonPropertyName("頭數")]
    public int HeadCount { get; set; }

    [JsonPropertyName("平均重量")]
    public decimal AvgWeight { get; set; }

    [JsonPropertyName("上價")]
    public decimal UpperPrice { get; set; }

    [JsonPropertyName("下價")]
    public decimal LowerPrice { get; set; }

    [JsonPropertyName("平均價")]
    public decimal AvgPrice { get; set; }
}
