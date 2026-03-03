namespace VegettableApi.Models;

/// <summary>
/// 產品詳情 — 包含近期均價走勢與三年月均價
/// </summary>
public class ProductDetailDto
{
    /// <summary>作物代號</summary>
    public string CropCode { get; set; } = string.Empty;

    /// <summary>作物名稱</summary>
    public string CropName { get; set; } = string.Empty;

    /// <summary>品項別名</summary>
    public List<string> Aliases { get; set; } = new();

    /// <summary>主類別</summary>
    public string Category { get; set; } = string.Empty;

    /// <summary>蔬菜細分類</summary>
    public string? SubCategory { get; set; }

    /// <summary>當前均價 (元/公斤)</summary>
    public decimal AvgPrice { get; set; }

    /// <summary>歷史同月均價 (元/公斤)</summary>
    public decimal HistoricalAvgPrice { get; set; }

    /// <summary>價格等級</summary>
    public string PriceLevel { get; set; } = "normal";

    /// <summary>趨勢</summary>
    public string Trend { get; set; } = "stable";

    /// <summary>近七日每日均價</summary>
    public List<DailyPriceDto> DailyPrices { get; set; } = new();

    /// <summary>近三年月均價 (用於長期趨勢圖)</summary>
    public List<MonthlyPriceDto> MonthlyPrices { get; set; } = new();
}
