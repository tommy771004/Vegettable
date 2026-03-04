namespace VegettableApi.Data.Entities;

/// <summary>
/// 價格警示 — 使用者設定「某品項低於/高於某價格時通知」
/// </summary>
public class PriceAlert
{
    public int Id { get; set; }

    /// <summary>裝置 Push Token (Expo push token)</summary>
    public string DeviceToken { get; set; } = string.Empty;

    /// <summary>作物名稱</summary>
    public string CropName { get; set; } = string.Empty;

    /// <summary>目標價格 (元/公斤)</summary>
    public decimal TargetPrice { get; set; }

    /// <summary>條件: below (低於) 或 above (高於)</summary>
    public string Condition { get; set; } = "below";

    /// <summary>是否啟用</summary>
    public bool IsActive { get; set; } = true;

    /// <summary>上次觸發時間 (避免重複通知)</summary>
    public DateTime? LastTriggeredAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
