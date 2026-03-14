namespace VegettableApi.Models;

/// <summary>畜產品行情 DTO</summary>
public class LivestockPriceDto
{
    public string LivestockCode { get; set; } = string.Empty;
    public string LivestockName { get; set; } = string.Empty;
    public string MarketName { get; set; } = string.Empty;
    public decimal AvgPrice { get; set; }
    public decimal UpperPrice { get; set; }
    public decimal LowerPrice { get; set; }
    public int HeadCount { get; set; }
    public decimal AvgWeight { get; set; }
    public string TransDate { get; set; } = string.Empty;
    /// <summary>近期均價趨勢: up / down / stable</summary>
    public string Trend { get; set; } = "stable";
}
