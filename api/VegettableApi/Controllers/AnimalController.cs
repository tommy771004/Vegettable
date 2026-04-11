using Microsoft.AspNetCore.Mvc;
using VegettableApi.Models;
using VegettableApi.Services;

namespace VegettableApi.Controllers;

/// <summary>
/// 毛豬行情 API — 整合農業部 AnimalTransData (肉品市場)
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class AnimalController : ControllerBase
{
    private readonly IAnimalService _animalService;

    public AnimalController(IAnimalService animalService) => _animalService = animalService;

    /// <summary>
    /// 取得近期毛豬行情
    /// </summary>
    /// <param name="productName">產品名稱（可選，如：毛豬、子豬）</param>
    /// <param name="market">市場名稱（可選）</param>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<AnimalPriceDto>>), 200)]
    public async Task<IActionResult> GetAnimalPrices(
        [FromQuery] string? productName = null,
        [FromQuery] string? market = null)
    {
        var data = await _animalService.GetRecentAnimalPricesAsync(productName, market);
        return Ok(ApiResponse<List<AnimalPriceDto>>.Ok(data));
    }
}
