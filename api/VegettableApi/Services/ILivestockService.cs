using VegettableApi.Models;

namespace VegettableApi.Services;

public interface ILivestockService
{
    Task<List<LivestockPriceDto>> GetRecentLivestockPricesAsync(string? livestockName = null);
}
