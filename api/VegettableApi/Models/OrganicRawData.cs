using System.Text.Json.Serialization;

namespace VegettableApi.Models;

/// <summary>
/// 農業部開放資料 — 產銷履歷與有機蔬果行情原始資料 (TAPData.aspx)
/// </summary>
public class OrganicRawData
{
    [JsonPropertyName("交易日期")]
    public string TransDate { get; set; } = string.Empty;

    [JsonPropertyName("作物代號")]
    public string CropCode { get; set; } = string.Empty;

    [JsonPropertyName("作物名稱")]
    public string CropName { get; set; } = string.Empty;

    [JsonPropertyName("市場代號")]
    public string MarketCode { get; set; } = string.Empty;

    [JsonPropertyName("市場名稱")]
    public string MarketName { get; set; } = string.Empty;

    [JsonPropertyName("上價")]
    public decimal UpperPrice { get; set; }

    [JsonPropertyName("下價")]
    public decimal LowerPrice { get; set; }

    [JsonPropertyName("平均價")]
    public decimal AvgPrice { get; set; }

    [JsonPropertyName("交易量")]
    public decimal Volume { get; set; }

    /// <summary>認驗證類別: "有機" 或 "產銷履歷"</summary>
    [JsonPropertyName("認驗證類別")]
    public string CertType { get; set; } = string.Empty;
}
