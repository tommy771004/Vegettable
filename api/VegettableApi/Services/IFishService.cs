using VegettableApi.Models;

namespace VegettableApi.Services;

public interface IFishService
{
    Task<List<AquaticPriceDto>> GetRecentFishPricesAsync(string? fishName = null, string? market = null);
    Task<List<AquaticPriceDto>> GetFishPricesByMarketAsync(string marketName, string? fishName = null);
}
