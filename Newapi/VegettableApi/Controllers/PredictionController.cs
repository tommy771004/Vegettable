using Microsoft.AspNetCore.Mvc;
using VegettableApi.Models;
using VegettableApi.Services;

namespace VegettableApi.Controllers;

/// <summary>
/// AI 預測、季節性、食譜推薦 API
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class PredictionController : ControllerBase
{
    private readonly IPredictionService _predictionService;

    public PredictionController(IPredictionService predictionService)
        => _predictionService = predictionService;

    /// <summary>
    /// AI 價格預測
    /// </summary>
    [HttpGet("{cropName}")]
    [ProducesResponseType(typeof(ApiResponse<PredictionDto>), 200)]
    public async Task<IActionResult> Predict(string cropName)
    {
        if (string.IsNullOrWhiteSpace(cropName))
            return BadRequest(ApiResponse<object>.Fail("請提供作物名稱"));

        var prediction = await _predictionService.PredictPriceAsync(cropName);
        return Ok(ApiResponse<PredictionDto>.Ok(prediction));
    }

    /// <summary>
    /// 季節性資訊
    /// </summary>
    [HttpGet("seasonal")]
    [ProducesResponseType(typeof(ApiResponse<List<SeasonalInfoDto>>), 200)]
    public IActionResult GetSeasonalInfo([FromQuery] string? category = null)
    {
        var info = _predictionService.GetSeasonalInfo(category);
        return Ok(ApiResponse<List<SeasonalInfoDto>>.Ok(info));
    }

    /// <summary>
    /// 食譜推薦
    /// </summary>
    [HttpGet("{cropName}/recipes")]
    [ProducesResponseType(typeof(ApiResponse<List<RecipeDto>>), 200)]
    public IActionResult GetRecipes(string cropName)
    {
        if (string.IsNullOrWhiteSpace(cropName))
            return BadRequest(ApiResponse<object>.Fail("請提供作物名稱"));

        var recipes = _predictionService.GetRecipesForCrop(cropName);
        return Ok(ApiResponse<List<RecipeDto>>.Ok(recipes));
    }
}
