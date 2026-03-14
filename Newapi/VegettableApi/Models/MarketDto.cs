namespace VegettableApi.Models;

/// <summary>
/// 批發市場資訊
/// </summary>
public class MarketDto
{
    public string MarketCode { get; set; } = string.Empty;
    public string MarketName { get; set; } = string.Empty;
    public string Region { get; set; } = string.Empty;
}
