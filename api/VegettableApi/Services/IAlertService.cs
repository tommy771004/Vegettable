using VegettableApi.Models;

namespace VegettableApi.Services;

public interface IAlertService
{
    Task<List<PriceAlertDto>> GetAlertsAsync(string deviceToken);
    Task<PriceAlertDto> CreateAlertAsync(CreateAlertRequest request);
    Task<bool> DeleteAlertAsync(int alertId, string deviceToken);
    Task<bool> ToggleAlertAsync(int alertId, string deviceToken);
    Task CheckAndTriggerAlertsAsync();
}
