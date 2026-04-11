namespace VegettableApi.Models;

/// <summary>花卉行情 DTO</summary>
public class FlowerPriceDto
{
    public string FlowerCode { get; set; } = string.Empty;
    public string FlowerName { get; set; } = string.Empty;
    public string FlowerType { get; set; } = string.Empty;
    public string MarketName { get; set; } = string.Empty;
    public decimal AvgPrice { get; set; }
    public decimal UpperPrice { get; set; }
    public decimal LowerPrice { get; set; }
    public decimal Volume { get; set; }
    public string TransDate { get; set; } = string.Empty;
    /// <summary>近期均價趨勢: up / down / stable</summary>
    public string Trend { get; set; } = "stable";
}
