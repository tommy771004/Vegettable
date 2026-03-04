using Microsoft.AspNetCore.Mvc;
using VegettableApi.Models;
using VegettableApi.Services;

namespace VegettableApi.Controllers;

/// <summary>
/// 批發市場 API
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class MarketsController : ControllerBase
{
    private readonly IMarketService _marketService;

    public MarketsController(IMarketService marketService) => _marketService = marketService;

    /// <summary>
    /// 取得所有批發市場清單
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<MarketDto>>), 200)]
    public IActionResult GetMarkets()
    {
        var markets = _marketService.GetMarkets();
        return Ok(ApiResponse<List<MarketDto>>.Ok(markets));
    }

    /// <summary>
    /// 取得指定市場的近期行情
    /// </summary>
    [HttpGet("{marketName}/prices")]
    [ProducesResponseType(typeof(ApiResponse<List<MarketPriceDto>>), 200)]
    public async Task<IActionResult> GetMarketPrices(
        string marketName, [FromQuery] string? cropName = null)
    {
        var prices = await _marketService.GetMarketPricesAsync(marketName, cropName);
        return Ok(ApiResponse<List<MarketPriceDto>>.Ok(prices));
    }

    /// <summary>
    /// 比較多個市場的同一產品價格
    /// </summary>
    [HttpGet("compare/{cropName}")]
    [ProducesResponseType(typeof(ApiResponse<List<MarketPriceDto>>), 200)]
    public async Task<IActionResult> CompareMarkets(
        string cropName, [FromQuery] string? markets = null)
    {
        var marketList = markets?.Split(',').Select(m => m.Trim()).ToList();
        var result = await _marketService.CompareMarketPricesAsync(cropName, marketList);
        return Ok(ApiResponse<List<MarketPriceDto>>.Ok(result));
    }
}
