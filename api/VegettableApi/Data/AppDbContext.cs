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
            e.HasIndex(a => new { a.CropName, a.IsActive });
        });

        modelBuilder.Entity<CachedDailyPrice>(e =>
        {
            e.HasIndex(c => new { c.CropName, c.TransDate });
            e.HasIndex(c => new { c.MarketName, c.TransDate });
            e.HasIndex(c => c.FetchedAt);
        });
    }
}
