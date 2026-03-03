using VegettableApi.Models;

namespace VegettableApi.Services;

/// <summary>
/// 產品服務介面 — 聚合農業部原始資料為前端可用格式
/// </summary>
public interface IProductService
{
    /// <summary>取得所有近期產品摘要列表</summary>
    Task<List<ProductSummaryDto>> GetRecentProductsAsync(string? category = null);

    /// <summary>取得特定產品的詳情（含七日走勢、三年月均價）</summary>
    Task<ProductDetailDto> GetProductDetailAsync(string cropName);

    /// <summary>取得所有分類清單</summary>
    List<CategoryDto> GetCategories();

    /// <summary>搜尋產品（支援別名搜尋）</summary>
    Task<List<ProductSummaryDto>> SearchProductsAsync(string keyword);
}
