namespace VegettableApi.Models;

/// <summary>
/// 市場價格 DTO
/// </summary>
public class MarketPriceDto
{
    public string MarketName { get; set; } = string.Empty;
    public string CropName { get; set; } = string.Empty;
    public decimal AvgPrice { get; set; }
    public decimal UpperPrice { get; set; }
    public decimal LowerPrice { get; set; }
    public decimal Volume { get; set; }
    public DateTime TransDate { get; set; }
}
