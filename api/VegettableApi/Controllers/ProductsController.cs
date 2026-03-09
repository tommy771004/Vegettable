using Microsoft.AspNetCore.Mvc;
using VegettableApi.Models;
using VegettableApi.Services;

namespace VegettableApi.Controllers;

/// <summary>
/// 農產品行情 API
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly IProductService _productService;

    public ProductsController(IProductService productService)
    {
        _productService = productService;
    }

    /// <summary>
    /// 取得近期產品行情列表（已依便宜程度排序）
    /// </summary>
    /// <param name="category">主類別篩選: vegetable, fruit, flower, fish, poultry, rice</param>
    /// <returns>產品摘要列表</returns>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<ProductSummaryDto>>), 200)]
    public async Task<IActionResult> GetRecentProducts([FromQuery] string? category = null)
    {
        var products = await _productService.GetRecentProductsAsync(category);
        return Ok(ApiResponse<List<ProductSummaryDto>>.Ok(products));
    }

    /// <summary>
    /// 取得近期產品行情列表（支援分頁）
    /// </summary>
    /// <param name="category">主類別篩選</param>
    /// <param name="offset">分頁起始位置 (0-based)</param>
    /// <param name="limit">每頁筆數 (1-100，預設 20)</param>
    [HttpGet("paginated")]
    [ProducesResponseType(typeof(ApiResponse<PaginatedResponse<ProductSummaryDto>>), 200)]
    public async Task<IActionResult> GetRecentProductsPaginated(
        [FromQuery] string? category = null,
        [FromQuery] int offset = 0,
        [FromQuery] int limit = 20)
    {
        var result = await _productService.GetRecentProductsPaginatedAsync(category, offset, limit);
        return Ok(ApiResponse<PaginatedResponse<ProductSummaryDto>>.Ok(result));
    }

    /// <summary>
    /// 搜尋產品（支援別名搜尋，如「地瓜」可找到「甘薯」）
    /// </summary>
    /// <param name="keyword">搜尋關鍵字</param>
    [HttpGet("search")]
    [ProducesResponseType(typeof(ApiResponse<List<ProductSummaryDto>>), 200)]
    public async Task<IActionResult> SearchProducts([FromQuery] string keyword)
    {
        if (string.IsNullOrWhiteSpace(keyword))
            return BadRequest(ApiResponse<object>.Fail("請輸入搜尋關鍵字"));

        var results = await _productService.SearchProductsAsync(keyword);
        return Ok(ApiResponse<List<ProductSummaryDto>>.Ok(results));
    }

    /// <summary>
    /// 搜尋產品（支援分頁）
    /// </summary>
    /// <param name="keyword">搜尋關鍵字</param>
    /// <param name="offset">分頁起始位置 (0-based)</param>
    /// <param name="limit">每頁筆數 (1-100，預設 20)</param>
    [HttpGet("search/paginated")]
    [ProducesResponseType(typeof(ApiResponse<PaginatedResponse<ProductSummaryDto>>), 200)]
    public async Task<IActionResult> SearchProductsPaginated(
        [FromQuery] string keyword,
        [FromQuery] int offset = 0,
        [FromQuery] int limit = 20)
    {
        if (string.IsNullOrWhiteSpace(keyword))
            return BadRequest(ApiResponse<object>.Fail("請輸入搜尋關鍵字"));

        var result = await _productService.SearchProductsPaginatedAsync(keyword, offset, limit);
        return Ok(ApiResponse<PaginatedResponse<ProductSummaryDto>>.Ok(result));
    }

    /// <summary>
    /// 取得特定產品詳情（含七日均價走勢、三年月均價）
    /// </summary>
    /// <param name="cropName">作物名稱</param>
    [HttpGet("{cropName}")]
    [ProducesResponseType(typeof(ApiResponse<ProductDetailDto>), 200)]
    [ProducesResponseType(typeof(ApiResponse<object>), 404)]
    public async Task<IActionResult> GetProductDetail(string cropName)
    {
        if (string.IsNullOrWhiteSpace(cropName))
            return BadRequest(ApiResponse<object>.Fail("請提供作物名稱"));
        try
        {
            var detail = await _productService.GetProductDetailAsync(cropName);
            return Ok(ApiResponse<ProductDetailDto>.Ok(detail));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message));
        }
    }
}
