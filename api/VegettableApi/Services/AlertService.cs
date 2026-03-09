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
        return await _db.PriceAlerts
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
        var alert = new PriceAlert
        {
            DeviceToken = request.DeviceToken,
            CropName = request.CropName,
            TargetPrice = request.TargetPrice,
            Condition = request.Condition,
        };

        _db.PriceAlerts.Add(alert);
        await _db.SaveChangesAsync();

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
        var alert = await _db.PriceAlerts
            .FirstOrDefaultAsync(a => a.Id == alertId && a.DeviceToken == deviceToken);

        if (alert == null) return false;

        _db.PriceAlerts.Remove(alert);
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> ToggleAlertAsync(int alertId, string deviceToken)
    {
        var alert = await _db.PriceAlerts
            .FirstOrDefaultAsync(a => a.Id == alertId && a.DeviceToken == deviceToken);

        if (alert == null) return false;

        alert.IsActive = !alert.IsActive;
        await _db.SaveChangesAsync();
        return true;
    }

    /// <summary>
    /// 背景排程呼叫 — 檢查所有啟用中的警示，觸發符合條件的通知
    /// </summary>
    public async Task CheckAndTriggerAlertsAsync()
    {
        var activeAlerts = await _db.PriceAlerts
            .Where(a => a.IsActive)
            .Where(a => a.LastTriggeredAt == null || a.LastTriggeredAt < DateTime.UtcNow.AddHours(-6))
            .ToListAsync();

        if (activeAlerts.Count == 0) return;

        var products = await _productService.GetRecentProductsAsync();
        var priceMap = products.ToDictionary(p => p.CropName, p => p.AvgPrice);

        foreach (var alert in activeAlerts)
        {
            if (!priceMap.TryGetValue(alert.CropName, out var currentPrice)) continue;

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
        }

        await _db.SaveChangesAsync();
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

            await http.PostAsync("https://exp.host/--/api/v2/push/send", content);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to send push notification to {Token}", alert.DeviceToken);
        }
    }
}
