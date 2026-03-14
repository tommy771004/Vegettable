using VegettableApi.Models;

namespace VegettableApi.Services;

public interface IPredictionService
{
    Task<PredictionDto> PredictPriceAsync(string cropName);
    List<SeasonalInfoDto> GetSeasonalInfo(string? category = null);
    List<RecipeDto> GetRecipesForCrop(string cropName);
}
