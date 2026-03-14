using Microsoft.AspNetCore.Mvc;
using VegettableApi.Models;
using VegettableApi.Services;

namespace VegettableApi.Controllers;

/// <summary>
/// 有機/產銷履歷蔬果行情 API — 整合農業部 TAPData
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class OrganicController : ControllerBase
{
    private readonly IOrganicService _organicService;

    public OrganicController(IOrganicService organicService) => _organicService = organicService;

    /// <summary>
    /// 取得近期有機/產銷履歷蔬果行情
    /// </summary>
    /// <param name="cropName">作物名稱（可選）</param>
    /// <param name="certType">認驗證類別：有機 或 產銷履歷（可選）</param>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<OrganicPriceDto>>), 200)]
    public async Task<IActionResult> GetOrganicPrices(
        [FromQuery] string? cropName = null,
        [FromQuery] string? certType = null)
    {
        var data = await _organicService.GetRecentOrganicPricesAsync(cropName, certType);
        return Ok(ApiResponse<List<OrganicPriceDto>>.Ok(data));
    }
}
