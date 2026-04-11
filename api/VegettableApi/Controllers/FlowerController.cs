using Microsoft.AspNetCore.Mvc;
using VegettableApi.Models;
using VegettableApi.Services;

namespace VegettableApi.Controllers;

/// <summary>
/// 花卉行情 API — 整合農業部 FlowerData
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class FlowerController : ControllerBase
{
    private readonly IFlowerService _flowerService;

    public FlowerController(IFlowerService flowerService) => _flowerService = flowerService;

    /// <summary>
    /// 取得近期花卉行情列表
    /// </summary>
    /// <param name="flowerName">花卉名稱（可選，如：玫瑰、菊花）</param>
    /// <param name="market">市場名稱（可選）</param>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<FlowerPriceDto>>), 200)]
    public async Task<IActionResult> GetFlowerPrices(
        [FromQuery] string? flowerName = null,
        [FromQuery] string? market = null)
    {
        var data = await _flowerService.GetRecentFlowerPricesAsync(flowerName, market);
        return Ok(ApiResponse<List<FlowerPriceDto>>.Ok(data));
    }

    /// <summary>
    /// 取得特定市場的花卉行情
    /// </summary>
    /// <param name="marketName">市場名稱</param>
    /// <param name="flowerName">花卉名稱（可選）</param>
    [HttpGet("{marketName}/prices")]
    [ProducesResponseType(typeof(ApiResponse<List<FlowerPriceDto>>), 200)]
    [ProducesResponseType(typeof(ApiResponse<object>), 400)]
    public async Task<IActionResult> GetFlowerPricesByMarket(
        string marketName,
        [FromQuery] string? flowerName = null)
    {
        if (string.IsNullOrWhiteSpace(marketName))
            return BadRequest(ApiResponse<object>.Fail("請提供市場名稱"));

        var data = await _flowerService.GetFlowerPricesByMarketAsync(marketName, flowerName);
        return Ok(ApiResponse<List<FlowerPriceDto>>.Ok(data));
    }
}
