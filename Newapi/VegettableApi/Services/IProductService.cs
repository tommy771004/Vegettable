using VegettableApi.Models;

namespace VegettableApi.Services;

public interface IProductService
{
    /// <summary>
    /// 取得近期產品列表（選擇性依類別篩選）
    /// </summary>
    Task<List<ProductSummaryDto>> GetRecentProductsAsync(string? category = null);

    /// <summary>
    /// 取得特定產品詳情
    /// </summary>
    Task<ProductDetailDto> GetProductDetailAsync(string cropName);

    /// <summary>
    /// 取得所有分類資訊
    /// </summary>
    List<CategoryDto> GetCategories();

    /// <summary>
    /// 搜尋產品（支援別名搜尋）
    /// </summary>
    Task<List<ProductSummaryDto>> SearchProductsAsync(string keyword);

    /// <summary>
    /// 取得近期產品列表（分頁版本）
    /// </summary>
    Task<PaginatedResponse<ProductSummaryDto>> GetRecentProductsPaginatedAsync(
        string? category = null, int offset = 0, int limit = 20);

    /// <summary>
    /// 搜尋產品（分頁版本）
    /// </summary>
    Task<PaginatedResponse<ProductSummaryDto>> SearchProductsPaginatedAsync(
        string keyword, int offset = 0, int limit = 20);
}
