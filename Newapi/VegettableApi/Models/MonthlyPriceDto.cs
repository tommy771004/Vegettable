namespace VegettableApi.Models;

/// <summary>
/// 月均價 DTO
/// </summary>
public class MonthlyPriceDto
{
    /// <summary>月份字串，格式："YYYY/MM"</summary>
    public string Month { get; set; } = string.Empty;
    public decimal AvgPrice { get; set; }
}
