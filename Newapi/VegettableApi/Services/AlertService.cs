using Microsoft.EntityFrameworkCore;
using VegettableApi.Data;
using VegettableApi.Data.Entities;
using VegettableApi.Models;

namespace VegettableApi.Services;

public class AlertService : IAlertService
{
    private readonly AppDbContext _db;
    private readonly IProductService _productService;
    private readonly ILogger<AlertService> _logger;
    private readonly IHttpClientFactory _httpClientFactory;

    public AlertService(AppDbContext db, IProductService productService, ILogger<AlertService> logger, IHttpClientFactory httpClientFactory)
    {
        _db = db;
        _productService = productService;
        _logger = logger;
        _httpClientFactory = httpClientFactory;
    }

    public async Task<List<PriceAlertDto>> GetAlertsAsync(string deviceToken)
    {
        if (string.IsNullOrWhiteSpace(deviceToken))
        {
            _logger.LogWarning("GetAlertsAsync called with empty deviceToken");
            return new List<PriceAlertDto>();
        }

        return await _db.PriceAlerts
            .AsNoTracking()
            .Where(a => a.DeviceToken == deviceToken)
            .OrderByDescending(a => a.CreatedAt)
            .Select(a => new PriceAlertDto
            {
                Id = a.Id,
                CropName = a.CropName,
                TargetPrice = a.TargetPrice,
                Condition = a.Condition,
                IsActive = a.IsActive,
                LastTriggeredAt = a.LastTriggeredAt,
                CreatedAt = a.CreatedAt,
            })
            .ToListAsync();
    }

    public async Task<PriceAlertDto> CreateAlertAsync(CreateAlertRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.DeviceToken) || string.IsNullOrWhiteSpace(request.CropName))
        {
            throw new ArgumentException("DeviceToken and CropName are required");
        }

        if (request.TargetPrice <= 0)
        {
            throw new ArgumentException("TargetPrice must be greater than 0");
        }

        if (request.Condition != "below" && request.Condition != "above")
        {
            throw new ArgumentException("Condition must be 'below' or 'above'");
        }

        var alert = new PriceAlert
        {
            DeviceToken = request.DeviceToken,
            CropName = request.CropName,
            TargetPrice = request.TargetPrice,
            Condition = request.Condition,
        };

        _db.PriceAlerts.Add(alert);
        await _db.SaveChangesAsync();

        _logger.LogInformation("Created price alert for device {Token} on crop {Crop} {Condition} ${Price}",
            request.DeviceToken[..Math.Min(8, request.DeviceToken.Length)],
            request.CropName, request.Condition, request.TargetPrice);

        return new PriceAlertDto
        {
            Id = alert.Id,
            CropName = alert.CropName,
            TargetPrice = alert.TargetPrice,
            Condition = alert.Condition,
            IsActive = alert.IsActive,
            CreatedAt = alert.CreatedAt,
        };
    }

    public async Task<bool> DeleteAlertAsync(int alertId, string deviceToken)
    {
        if (string.IsNullOrWhiteSpace(deviceToken))
        {
            _logger.LogWarning("DeleteAlertAsync called with empty deviceToken");
            return false;
        }

        var alert = await _db.PriceAlerts
            .FirstOrDefaultAsync(a => a.Id == alertId && a.DeviceToken == deviceToken);

        if (alert == null)
        {
            _logger.LogWarning("Alert not found: ID={AlertId}, Token={Token}", alertId, deviceToken[..Math.Min(8, deviceToken.Length)]);
            return false;
        }

        _db.PriceAlerts.Remove(alert);
        await _db.SaveChangesAsync();

        _logger.LogInformation("Deleted alert {AlertId}", alertId);
        return true;
    }

    public async Task<bool> ToggleAlertAsync(int alertId, string deviceToken)
    {
        if (string.IsNullOrWhiteSpace(deviceToken))
        {
            _logger.LogWarning("ToggleAlertAsync called with empty deviceToken");
            return false;
        }

        var alert = await _db.PriceAlerts
            .FirstOrDefaultAsync(a => a.Id == alertId && a.DeviceToken == deviceToken);

        if (alert == null)
        {
            _logger.LogWarning("Alert not found for toggle: ID={AlertId}, Token={Token}", alertId, deviceToken[..Math.Min(8, deviceToken.Length)]);
            return false;
        }

        alert.IsActive = !alert.IsActive;
        await _db.SaveChangesAsync();

        _logger.LogInformation("Toggled alert {AlertId} to {State}", alertId, alert.IsActive ? "active" : "inactive");
        return true;
    }

    /// <summary>
    /// 背景排程呼叫 — 檢查所有啟用中的警示，觸發符合條件的通知
    /// 使用分批查詢與 PLINQ 提升效能
    /// </summary>
    public async Task CheckAndTriggerAlertsAsync()
    {
        var activeAlerts = await _db.PriceAlerts
            .Where(a => a.IsActive)
            .Where(a => a.LastTriggeredAt == null || a.LastTriggeredAt < DateTime.UtcNow.AddHours(-6))
            .ToListAsync();

        if (activeAlerts.Count == 0)
        {
            _logger.LogDebug("No active alerts to check");
            return;
        }

        _logger.LogInformation("Checking {Count} active alerts", activeAlerts.Count);

        // 只取得有活躍警示的作物名稱，避免載入所有產品
        var neededCrops = activeAlerts.Select(a => a.CropName).Distinct().ToHashSet();

        try
        {
            var products = await _productService.GetRecentProductsAsync();
            var priceMap = products
                .Where(p => neededCrops.Contains(p.CropName))
                .ToDictionary(p => p.CropName, p => p.AvgPrice);

            var triggeredCount = 0;

            foreach (var alert in activeAlerts)
            {
                if (!priceMap.TryGetValue(alert.CropName, out var currentPrice))
                {
                    _logger.LogDebug("No price data for crop {Crop}", alert.CropName);
                    continue;
                }

                var triggered = alert.Condition == "below"
                    ? currentPrice <= alert.TargetPrice
                    : currentPrice >= alert.TargetPrice;

                if (!triggered) continue;

                _logger.LogInformation(
                    "Alert triggered: {CropName} {Condition} ${TargetPrice} (current: ${CurrentPrice})",
                    alert.CropName, alert.Condition, alert.TargetPrice, currentPrice);

                // 透過 Expo Push Notification 發送
                await SendPushNotificationAsync(alert, currentPrice);
                alert.LastTriggeredAt = DateTime.UtcNow;
                triggeredCount++;
            }

            await _db.SaveChangesAsync();
            _logger.LogInformation("Alert check completed: {Triggered} triggered", triggeredCount);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during alert check cycle");
        }
    }

    private async Task SendPushNotificationAsync(PriceAlert alert, decimal currentPrice)
    {
        var conditionText = alert.Condition == "below" ? "低於" : "高於";
        var body = $"{alert.CropName} 目前均價 ${currentPrice}/kg，已{conditionText}您設定的 ${alert.TargetPrice}/kg";

        try
        {
            var http = _httpClientFactory.CreateClient("ExpoPush");
            var payload = new
            {
                to = alert.DeviceToken,
                title = $"價格警示 — {alert.CropName}",
                body,
                data = new { cropName = alert.CropName, price = currentPrice },
            };

            var json = System.Text.Json.JsonSerializer.Serialize(payload);
            var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

            var response = await http.PostAsync("https://exp.host/--/api/v2/push/send", content);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Expo Push failed with status {Status}", response.StatusCode);
            }
        }
        catch (HttpRequestException ex)
        {
            _logger.LogWarning(ex, "HTTP error sending push notification to {Token}", alert.DeviceToken[..Math.Min(8, alert.DeviceToken.Length)]);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Unexpected error sending push notification to {Token}", alert.DeviceToken[..Math.Min(8, alert.DeviceToken.Length)]);
        }
    }
}
