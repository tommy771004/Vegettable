namespace VegettableApi.Models;

/// <summary>毛豬行情 DTO (肉品市場)</summary>
public class AnimalPriceDto
{
    public string ProductCode { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
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
