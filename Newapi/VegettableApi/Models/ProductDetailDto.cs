namespace VegettableApi.Models;

/// <summary>
/// 產品詳情 DTO — 包含七日走勢、三年月均價
/// </summary>
public class ProductDetailDto
{
    public string CropName { get; set; } = string.Empty;
    public string CropCode { get; set; } = string.Empty;

    /// <summary>目前均價</summary>
    public decimal AvgPrice { get; set; }

    /// <summary>價格水位："high" (高)、"normal" (正常)、"low" (低)</summary>
    public string PriceLevel { get; set; } = "normal";

    /// <summary>價格趨勢："up" (上升)、"down" (下降)、"stable" (穩定)</summary>
    public string Trend { get; set; } = "stable";

    /// <summary>最近七天的日均價</summary>
    public List<DailyPriceDto> DailyPrices { get; set; } = new();

    /// <summary>預測用的每日價格（可能包含更長期間的資料）</summary>
    public List<DailyPriceDto> DailyPricesForPrediction { get; set; } = new();

    /// <summary>過去三年的月均價</summary>
    public List<MonthlyPriceDto> MonthlyPrices { get; set; } = new();

    /// <summary>別名清單</summary>
    public List<string> Aliases { get; set; } = new();
}
