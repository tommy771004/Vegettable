using Microsoft.AspNetCore.Mvc;
using VegettableApi.Models;
using VegettableApi.Services;

namespace VegettableApi.Controllers;

/// <summary>
/// 漁產品行情 API — 整合農業部 AquaticTransData
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class FishController : ControllerBase
{
    private readonly IFishService _fishService;

    public FishController(IFishService fishService) => _fishService = fishService;

    /// <summary>
    /// 取得近期漁產品行情列表
    /// </summary>
    /// <param name="fishName">魚貨名稱（可選，如：吳郭魚、虱目魚）</param>
    /// <param name="market">市場名稱（可選）</param>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<AquaticPriceDto>>), 200)]
    public async Task<IActionResult> GetFishPrices(
        [FromQuery] string? fishName = null,
        [FromQuery] string? market = null)
    {
        var data = await _fishService.GetRecentFishPricesAsync(fishName, market);
        return Ok(ApiResponse<List<AquaticPriceDto>>.Ok(data));
    }

    /// <summary>
    /// 取得特定市場的漁產品行情
    /// </summary>
    /// <param name="marketName">市場名稱</param>
    /// <param name="fishName">魚貨名稱（可選）</param>
    [HttpGet("{marketName}/prices")]
    [ProducesResponseType(typeof(ApiResponse<List<AquaticPriceDto>>), 200)]
    [ProducesResponseType(typeof(ApiResponse<object>), 400)]
    public async Task<IActionResult> GetFishPricesByMarket(
        string marketName,
        [FromQuery] string? fishName = null)
    {
        if (string.IsNullOrWhiteSpace(marketName))
            return BadRequest(ApiResponse<object>.Fail("請提供市場名稱"));

        var data = await _fishService.GetFishPricesByMarketAsync(marketName, fishName);
        return Ok(ApiResponse<List<AquaticPriceDto>>.Ok(data));
    }
}
