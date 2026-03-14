namespace VegettableApi.Models;

/// <summary>
/// 建立價格警示請求模型
/// </summary>
public class CreateAlertRequest
{
    /// <summary>裝置令牌 (用於 Expo Push Notification)</summary>
    public string DeviceToken { get; set; } = string.Empty;

    /// <summary>作物名稱</summary>
    public string CropName { get; set; } = string.Empty;

    /// <summary>目標價格</summary>
    public decimal TargetPrice { get; set; }

    /// <summary>條件："below" (低於) 或 "above" (高於)</summary>
    public string Condition { get; set; } = "below";
}
