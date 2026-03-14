namespace VegettableApi.Models;

/// <summary>漁產品行情 DTO</summary>
public class AquaticPriceDto
{
    public string FishCode { get; set; } = string.Empty;
    public string FishName { get; set; } = string.Empty;
    public string MarketName { get; set; } = string.Empty;
    public decimal AvgPrice { get; set; }
    public decimal UpperPrice { get; set; }
    public decimal LowerPrice { get; set; }
    public decimal Volume { get; set; }
    public string TransDate { get; set; } = string.Empty;
    /// <summary>近期均價趨勢: up / down / stable</summary>
    public string Trend { get; set; } = "stable";
}
