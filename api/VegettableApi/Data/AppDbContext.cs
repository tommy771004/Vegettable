using Microsoft.EntityFrameworkCore;
using VegettableApi.Data.Entities;

namespace VegettableApi.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<PriceAlert> PriceAlerts => Set<PriceAlert>();
    public DbSet<CachedDailyPrice> CachedDailyPrices => Set<CachedDailyPrice>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<PriceAlert>(e =>
        {
            e.HasIndex(a => a.DeviceToken);
            e.HasIndex(a => a.IsActive); // 用於背景服務查詢所有活躍警示
            e.HasIndex(a => new { a.IsActive, a.CropName }); // 組合查詢優化
            e.HasIndex(a => new { a.DeviceToken, a.IsActive }); // 用戶特定警示查詢
        });

        modelBuilder.Entity<CachedDailyPrice>(e =>
        {
            e.HasIndex(c => new { c.CropName, c.TransDate });
            e.HasIndex(c => new { c.MarketName, c.TransDate });
            e.HasIndex(c => c.FetchedAt);
            // 唯一約束 — 防止高併發下寫入重複資料
            e.HasIndex(c => new { c.CropName, c.MarketName, c.TransDate }).IsUnique();
        });
    }
}
