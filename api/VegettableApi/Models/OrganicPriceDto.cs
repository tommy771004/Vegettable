namespace VegettableApi.Models;

/// <summary>有機/產銷履歷蔬果行情 DTO</summary>
public class OrganicPriceDto
{
    public string CropCode { get; set; } = string.Empty;
    public string CropName { get; set; } = string.Empty;
    public string MarketName { get; set; } = string.Empty;
    public decimal AvgPrice { get; set; }
    public decimal UpperPrice { get; set; }
    public decimal LowerPrice { get; set; }
    public decimal Volume { get; set; }
    /// <summary>認驗證類別: "有機" 或 "產銷履歷"</summary>
    public string CertType { get; set; } = string.Empty;
    public string TransDate { get; set; } = string.Empty;
    /// <summary>與一般批發均價差異百分比（正值代表有機較貴）</summary>
    public decimal? PremiumPercent { get; set; }
}
