using VegettableApi.Models;

namespace VegettableApi.Services;

public interface IFlowerService
{
    Task<List<FlowerPriceDto>> GetRecentFlowerPricesAsync(string? flowerName = null, string? market = null);
    Task<List<FlowerPriceDto>> GetFlowerPricesByMarketAsync(string marketName, string? flowerName = null);
}
