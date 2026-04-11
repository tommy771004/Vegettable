using Microsoft.AspNetCore.Mvc;
using VegettableApi.Models;
using VegettableApi.Services;

namespace VegettableApi.Controllers;

/// <summary>
/// 農業氣象 API — 整合農業部 AgrWeatherData
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class WeatherController : ControllerBase
{
    private readonly IAgrWeatherService _weatherService;

    public WeatherController(IAgrWeatherService weatherService) => _weatherService = weatherService;

    /// <summary>
    /// 取得各農業氣象站最新觀測資料
    /// </summary>
    /// <param name="county">縣市名稱篩選（可選，如：台北市、台中市）</param>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<WeatherObservationDto>>), 200)]
    public async Task<IActionResult> GetLatestObservations(
        [FromQuery] string? county = null)
    {
        var data = await _weatherService.GetLatestObservationsAsync(county);
        return Ok(ApiResponse<List<WeatherObservationDto>>.Ok(data));
    }

    /// <summary>
    /// 取得指定測站近期觀測記錄
    /// </summary>
    /// <param name="stationId">測站代碼</param>
    /// <param name="days">查詢天數（預設 7 天，最多 30 天）</param>
    [HttpGet("{stationId}/obs")]
    [ProducesResponseType(typeof(ApiResponse<List<WeatherObservationDto>>), 200)]
    [ProducesResponseType(typeof(ApiResponse<object>), 400)]
    public async Task<IActionResult> GetStationObservations(
        string stationId,
        [FromQuery] int days = 7)
    {
        if (string.IsNullOrWhiteSpace(stationId))
            return BadRequest(ApiResponse<object>.Fail("請提供測站代碼"));

        days = Math.Max(1, Math.Min(days, 30));
        var data = await _weatherService.GetStationObservationsAsync(stationId, days);
        return Ok(ApiResponse<List<WeatherObservationDto>>.Ok(data));
    }
}
