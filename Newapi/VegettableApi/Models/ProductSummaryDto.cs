namespace VegettableApi.Models;

/// <summary>
/// 產品摘要 DTO — 用於列表顯示
/// </summary>
public class ProductSummaryDto
{
    public string CropName { get; set; } = string.Empty;
    public string CropCode { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public decimal AvgPrice { get; set; }
    public string PriceLevel { get; set; } = "normal";
    public string Trend { get; set; } = "stable";
    public DateTime LastUpdated { get; set; }
}
