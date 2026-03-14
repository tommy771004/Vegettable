using Microsoft.AspNetCore.Mvc;
using VegettableApi.Models;
using VegettableApi.Services;

namespace VegettableApi.Controllers;

/// <summary>
/// 畜產品行情 API — 整合農業部 LivestockTransData
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class LivestockController : ControllerBase
{
    private readonly ILivestockService _livestockService;

    public LivestockController(ILivestockService livestockService) => _livestockService = livestockService;

    /// <summary>
    /// 取得近期畜產品行情列表
    /// </summary>
    /// <param name="livestockName">牲畜名稱（可選，如：毛豬、肉雞）</param>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<LivestockPriceDto>>), 200)]
    public async Task<IActionResult> GetLivestockPrices([FromQuery] string? livestockName = null)
    {
        var data = await _livestockService.GetRecentLivestockPricesAsync(livestockName);
        return Ok(ApiResponse<List<LivestockPriceDto>>.Ok(data));
    }
}
