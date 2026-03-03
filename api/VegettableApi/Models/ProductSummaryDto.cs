namespace VegettableApi.Models;

/// <summary>
/// 產品摘要 — 給前端列表頁使用
/// </summary>
public class ProductSummaryDto
{
    /// <summary>作物代號</summary>
    public string CropCode { get; set; } = string.Empty;

    /// <summary>作物名稱（官方）</summary>
    public string CropName { get; set; } = string.Empty;

    /// <summary>批發均價 (元/公斤)</summary>
    public decimal AvgPrice { get; set; }

    /// <summary>前一交易日均價 (元/公斤)</summary>
    public decimal PrevAvgPrice { get; set; }

    /// <summary>歷史同月份均價 (元/公斤)</summary>
    public decimal HistoricalAvgPrice { get; set; }

    /// <summary>近期總交易量 (公斤)</summary>
    public decimal Volume { get; set; }

    /// <summary>
    /// 價格等級: very-cheap, cheap, normal, expensive
    /// 前端用來顯示四色標籤
    /// </summary>
    public string PriceLevel { get; set; } = "normal";

    /// <summary>
    /// 趨勢: up, down, stable
    /// </summary>
    public string Trend { get; set; } = "stable";

    /// <summary>近七天每日均價</summary>
    public List<DailyPriceDto> RecentPrices { get; set; } = new();

    /// <summary>
    /// 主類別: vegetable, fruit, flower, fish, poultry, rice
    /// </summary>
    public string Category { get; set; } = "vegetable";

    /// <summary>蔬菜細分類 (僅 category=vegetable 有值)</summary>
    public string? SubCategory { get; set; }

    /// <summary>品項別名</summary>
    public List<string> Aliases { get; set; } = new();
}
