using VegettableApi.Models;

namespace VegettableApi.Services;

public interface IAnimalService
{
    Task<List<AnimalPriceDto>> GetRecentAnimalPricesAsync(string? productName = null, string? market = null);
}
