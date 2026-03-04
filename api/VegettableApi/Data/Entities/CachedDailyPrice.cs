namespace VegettableApi.Data.Entities;

/// <summary>
/// 持久化每日交易行情 — 避免重複呼叫農業部 API
/// </summary>
public class CachedDailyPrice
{
    public int Id { get; set; }
    public string CropCode { get; set; } = string.Empty;
    public string CropName { get; set; } = string.Empty;
    public string MarketCode { get; set; } = string.Empty;
    public string MarketName { get; set; } = string.Empty;
    public string TransDate { get; set; } = string.Empty;
    public decimal AvgPrice { get; set; }
    public decimal UpperPrice { get; set; }
    public decimal MiddlePrice { get; set; }
    public decimal LowerPrice { get; set; }
    public decimal Volume { get; set; }
    public DateTime FetchedAt { get; set; } = DateTime.UtcNow;
}
