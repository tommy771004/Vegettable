using Microsoft.AspNetCore.Mvc;
using VegettableApi.Models;
using VegettableApi.Services;

namespace VegettableApi.Controllers;

/// <summary>
/// 分類資訊 API
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class CategoriesController : ControllerBase
{
    private readonly IProductService _productService;

    public CategoriesController(IProductService productService)
    {
        _productService = productService;
    }

    /// <summary>
    /// 取得所有分類清單（含蔬菜子分類）
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<CategoryDto>>), 200)]
    public IActionResult GetCategories()
    {
        var categories = _productService.GetCategories();
        return Ok(ApiResponse<List<CategoryDto>>.Ok(categories));
    }
}
