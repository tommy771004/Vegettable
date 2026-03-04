using Microsoft.EntityFrameworkCore;
using VegettableApi.Data;
using VegettableApi.Data.Entities;

namespace VegettableApi.Services;

/// <summary>
/// 背景排程服務 — 定時從農業部抓取資料寫入 SQLite，
/// 同時每 30 分鐘檢查價格警示
/// </summary>
public class DataFetchBackgroundService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<DataFetchBackgroundService> _logger;

    /// <summary>資料同步間隔 (30 分鐘)</summary>
    private static readonly TimeSpan FetchInterval = TimeSpan.FromMinutes(30);

    public DataFetchBackgroundService(IServiceScopeFactory scopeFactory, ILogger<DataFetchBackgroundService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("DataFetchBackgroundService started");

        // 等待應用程式啟動完成
        await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await FetchAndCacheDataAsync(stoppingToken);
                await CheckPriceAlertsAsync(stoppingToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                _logger.LogError(ex, "Background data fetch failed");
            }

            await Task.Delay(FetchInterval, stoppingToken);
        }
    }

    private async Task FetchAndCacheDataAsync(CancellationToken ct)
    {
        using var scope = _scopeFactory.CreateScope();
        var moaApi = scope.ServiceProvider.GetRequiredService<IMoaApiService>();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var endDate = DateTime.Today;
        var startDate = endDate.AddDays(-7);

        _logger.LogInformation("Fetching farm data for cache: {Start} to {End}", startDate, endDate);

        var data = await moaApi.FetchFarmTransDataAsync(startDate, endDate);

        if (data.Count == 0) return;

        // 移除舊的快取資料 (7天前)
        var cutoff = DateTime.UtcNow.AddDays(-7);
        var oldEntries = await db.CachedDailyPrices
            .Where(c => c.FetchedAt < cutoff)
            .ToListAsync(ct);

        if (oldEntries.Count > 0)
        {
            db.CachedDailyPrices.RemoveRange(oldEntries);
            _logger.LogInformation("Removed {Count} stale cache entries", oldEntries.Count);
        }

        // 寫入新資料 (避免重複)
        var newCount = 0;
        foreach (var item in data)
        {
            var exists = await db.CachedDailyPrices.AnyAsync(c =>
                c.CropName == item.CropName &&
                c.MarketName == item.MarketName &&
                c.TransDate == item.TransDate, ct);

            if (exists) continue;

            db.CachedDailyPrices.Add(new CachedDailyPrice
            {
                CropCode = item.CropCode,
                CropName = item.CropName,
                MarketCode = item.MarketCode,
                MarketName = item.MarketName,
                TransDate = item.TransDate,
                AvgPrice = item.AvgPrice,
                UpperPrice = item.UpperPrice,
                MiddlePrice = item.MiddlePrice,
                LowerPrice = item.LowerPrice,
                Volume = item.Volume,
            });
            newCount++;
        }

        if (newCount > 0)
        {
            await db.SaveChangesAsync(ct);
            _logger.LogInformation("Cached {Count} new daily price records", newCount);
        }
    }

    private async Task CheckPriceAlertsAsync(CancellationToken ct)
    {
        using var scope = _scopeFactory.CreateScope();
        var alertService = scope.ServiceProvider.GetRequiredService<IAlertService>();

        _logger.LogDebug("Checking price alerts...");
        await alertService.CheckAndTriggerAlertsAsync();
    }
}
