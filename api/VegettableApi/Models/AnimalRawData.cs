using System.Text.Json.Serialization;

namespace VegettableApi.Models;

/// <summary>
/// 農業部開放資料 — 毛豬交易行情原始資料 (AnimalTransData.aspx)
/// Dataset: 肉品市場毛豬交易行情 (與 LivestockTransData 批發市場不同)
/// </summary>
public class AnimalRawData
{
    [JsonPropertyName("交易日期")]
    public string TransDate { get; set; } = string.Empty;

    [JsonPropertyName("產品代號")]
    public string ProductCode { get; set; } = string.Empty;

    [JsonPropertyName("產品名稱")]
    public string ProductName { get; set; } = string.Empty;

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
