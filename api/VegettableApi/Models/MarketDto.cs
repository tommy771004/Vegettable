namespace VegettableApi.Models;

/// <summary>
/// 批發市場資訊
/// </summary>
public class MarketDto
{
    public string MarketCode { get; set; } = string.Empty;
    public string MarketName { get; set; } = string.Empty;
    public string Region { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
}

/// <summary>
/// 特定市場的產品行情
/// </summary>
public class MarketPriceDto
{
    public string MarketName { get; set; } = string.Empty;
    public string CropName { get; set; } = string.Empty;
    public decimal AvgPrice { get; set; }
    public decimal UpperPrice { get; set; }
    public decimal LowerPrice { get; set; }
    public decimal Volume { get; set; }
    public string TransDate { get; set; } = string.Empty;
}
