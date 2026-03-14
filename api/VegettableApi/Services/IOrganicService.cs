using VegettableApi.Models;

namespace VegettableApi.Services;

public interface IOrganicService
{
    Task<List<OrganicPriceDto>> GetRecentOrganicPricesAsync(string? cropName = null, string? certType = null);
}
