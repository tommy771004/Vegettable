using VegettableApi.Models;

namespace VegettableApi.Services;

/// <summary>
/// 產品服務介面 — 聚合農業部原始資料為前端可用格式
/// </summary>
public interface IProductService
{
    /// <summary>取得所有近期產品摘要列表 (支援分頁)</summary>
    Task<List<ProductSummaryDto>> GetRecentProductsAsync(string? category = null);

    /// <summary>取得近期產品摘要列表 (含分頁元數據)</summary>
    Task<PaginatedResponse<ProductSummaryDto>> GetRecentProductsPaginatedAsync(string? category = null, int offset = 0, int limit = 20);

    /// <summary>取得特定產品的詳情（含七日走勢、三年月均價）</summary>
    Task<ProductDetailDto> GetProductDetailAsync(string cropName);

    /// <summary>取得所有分類清單</summary>
    List<CategoryDto> GetCategories();

    /// <summary>搜尋產品（支援別名搜尋）</summary>
    Task<List<ProductSummaryDto>> SearchProductsAsync(string keyword);

    /// <summary>搜尋產品 (支援分頁)</summary>
    Task<PaginatedResponse<ProductSummaryDto>> SearchProductsPaginatedAsync(string keyword, int offset = 0, int limit = 20);
}
