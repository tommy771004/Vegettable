using Microsoft.AspNetCore.Mvc;
using VegettableApi.Models;
using VegettableApi.Services;

namespace VegettableApi.Controllers;

/// <summary>
/// 價格警示 API
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class AlertsController : ControllerBase
{
    private readonly IAlertService _alertService;

    public AlertsController(IAlertService alertService) => _alertService = alertService;

    /// <summary>
    /// 取得裝置的所有價格警示
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<PriceAlertDto>>), 200)]
    public async Task<IActionResult> GetAlerts([FromQuery] string deviceToken)
    {
        if (string.IsNullOrWhiteSpace(deviceToken))
            return BadRequest(ApiResponse<object>.Fail("請提供 deviceToken"));

        var alerts = await _alertService.GetAlertsAsync(deviceToken);
        return Ok(ApiResponse<List<PriceAlertDto>>.Ok(alerts));
    }

    /// <summary>
    /// 建立新的價格警示
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<PriceAlertDto>), 201)]
    public async Task<IActionResult> CreateAlert([FromBody] CreateAlertRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.DeviceToken))
            return BadRequest(ApiResponse<object>.Fail("請提供 deviceToken"));
        if (string.IsNullOrWhiteSpace(request.CropName))
            return BadRequest(ApiResponse<object>.Fail("請提供作物名稱"));
        if (request.TargetPrice <= 0)
            return BadRequest(ApiResponse<object>.Fail("目標價格必須大於 0"));

        var alert = await _alertService.CreateAlertAsync(request);
        return Created($"/api/alerts/{alert.Id}", ApiResponse<PriceAlertDto>.Ok(alert));
    }

    /// <summary>
    /// 刪除價格警示
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteAlert(int id, [FromQuery] string deviceToken)
    {
        if (string.IsNullOrWhiteSpace(deviceToken))
            return BadRequest(ApiResponse<object>.Fail("請提供 deviceToken"));

        var result = await _alertService.DeleteAlertAsync(id, deviceToken);
        return result
            ? Ok(ApiResponse<object>.Ok(null!, "警示已刪除"))
            : NotFound(ApiResponse<object>.Fail("找不到該警示"));
    }

    /// <summary>
    /// 切換警示啟用/停用
    /// </summary>
    [HttpPatch("{id}/toggle")]
    public async Task<IActionResult> ToggleAlert(int id, [FromQuery] string deviceToken)
    {
        if (string.IsNullOrWhiteSpace(deviceToken))
            return BadRequest(ApiResponse<object>.Fail("請提供 deviceToken"));

        var result = await _alertService.ToggleAlertAsync(id, deviceToken);
        return result
            ? Ok(ApiResponse<object>.Ok(null!, "警示狀態已切換"))
            : NotFound(ApiResponse<object>.Fail("找不到該警示"));
    }
}
