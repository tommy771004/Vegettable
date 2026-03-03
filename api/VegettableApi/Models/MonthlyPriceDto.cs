namespace VegettableApi.Models;

/// <summary>
/// 月均價（用於三年趨勢圖）
/// </summary>
public class MonthlyPriceDto
{
    /// <summary>月份 (格式: 2024/01)</summary>
    public string Month { get; set; } = string.Empty;

    /// <summary>月均價 (元/公斤)</summary>
    public decimal AvgPrice { get; set; }

    /// <summary>月總交易量 (公斤)</summary>
    public decimal Volume { get; set; }
}
