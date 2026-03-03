namespace VegettableApi.Models;

/// <summary>
/// 單日均價
/// </summary>
public class DailyPriceDto
{
    /// <summary>交易日期 (yyyy-MM-dd 或民國年格式)</summary>
    public string Date { get; set; } = string.Empty;

    /// <summary>全市場加權平均價 (元/公斤)</summary>
    public decimal AvgPrice { get; set; }

    /// <summary>當日交易量 (公斤)</summary>
    public decimal Volume { get; set; }
}
