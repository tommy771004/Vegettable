namespace VegettableApi.Models;

/// <summary>
/// 日均價 DTO
/// </summary>
public class DailyPriceDto
{
    public DateTime TransDate { get; set; }
    public decimal AvgPrice { get; set; }
    public decimal UpperPrice { get; set; }
    public decimal LowerPrice { get; set; }
    public decimal Volume { get; set; }
}
