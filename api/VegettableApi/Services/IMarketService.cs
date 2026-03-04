using VegettableApi.Models;

namespace VegettableApi.Services;

/// <summary>
/// 批發市場服務介面
/// </summary>
public interface IMarketService
{
    /// <summary>取得所有批發市場清單</summary>
    List<MarketDto> GetMarkets();

    /// <summary>取得指定市場的近期行情</summary>
    Task<List<MarketPriceDto>> GetMarketPricesAsync(string marketName, string? cropName = null);

    /// <summary>比較多個市場的同一產品價格</summary>
    Task<List<MarketPriceDto>> CompareMarketPricesAsync(string cropName, List<string>? markets = null);
}
