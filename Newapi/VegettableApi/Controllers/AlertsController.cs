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

    private static bool IsValidDeviceToken(string token)
        => !string.IsNullOrWhiteSpace(token) && token.Length >= 20 && token.Length <= 300;

    /// <summary>
    /// 取得裝置的所有價格警示
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<PriceAlertDto>>), 200)]
    public async Task<IActionResult> GetAlerts([FromQuery] string deviceToken)
    {
        if (!IsValidDeviceToken(deviceToken))
            return BadRequest(ApiResponse<object>.Fail("deviceToken 格式無效"));

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
        if (!IsValidDeviceToken(request.DeviceToken))
            return BadRequest(ApiResponse<object>.Fail("deviceToken 格式無效"));
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
    /// <summary>
    /// Deletes the price alert with the specified id for the provided device token.
    /// </summary>
    /// <param name="id">The identifier of the alert to delete.</param>
    /// <param name="deviceToken">The device token that must match the alert's owner; required for authorization.</param>
    /// <returns>
    /// A result indicating the outcome:
    /// - Returns BadRequest when <paramref name="deviceToken"/> is missing or empty.
    /// - Returns Ok with an object { success = true, message = "警示已刪除", timestamp = &lt;milliseconds since epoch&gt; } when the alert is successfully deleted.
    /// - Returns NotFound with a failure ApiResponse when no matching alert is found.
    /// </returns>
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteAlert(int id, [FromQuery] string deviceToken)
    {
        if (!IsValidDeviceToken(deviceToken))
            return BadRequest(ApiResponse<object>.Fail("deviceToken 格式無效"));

        var result = await _alertService.DeleteAlertAsync(id, deviceToken);
        return result
            ? Ok(new { success = true, message = "警示已刪除", timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() })
            : NotFound(ApiResponse<object>.Fail("找不到該警示"));
    }

    /// <summary>
    /// 切換警示啟用/停用
    /// </summary>
    /// <summary>
    /// Toggles the enabled state of the price alert with the given id for the specified device.
    /// </summary>
    /// <param name="id">Identifier of the price alert to toggle.</param>
    /// <param name="deviceToken">Device token that owns the alert; required.</param>
    /// <returns>200 OK with { success = true, message, timestamp } when toggling succeeds; 400 Bad Request when deviceToken is missing; 404 Not Found when the alert cannot be found.</returns>
    [HttpPatch("{id}/toggle")]
    public async Task<IActionResult> ToggleAlert(int id, [FromQuery] string deviceToken)
    {
        if (!IsValidDeviceToken(deviceToken))
            return BadRequest(ApiResponse<object>.Fail("deviceToken 格式無效"));

        var result = await _alertService.ToggleAlertAsync(id, deviceToken);
        return result
            ? Ok(new { success = true, message = "警示狀態已切換", timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() })
            : NotFound(ApiResponse<object>.Fail("找不到該警示"));
    }
}
