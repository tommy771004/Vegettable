namespace VegettableApi.Data.Entities;

/// <summary>
/// 使用者回饋紀錄
/// </summary>
public class FeedbackSubmission
{
    public int Id { get; set; }

    /// <summary>回饋類型: bug | suggestion | other</summary>
    public string FeedbackType { get; set; } = "suggestion";

    /// <summary>回饋內容（10-2000 字）</summary>
    public string Content { get; set; } = string.Empty;

    /// <summary>裝置識別（選填，用於追蹤）</summary>
    public string? DeviceToken { get; set; }

    /// <summary>App 平台: ios | android</summary>
    public string? Platform { get; set; }

    /// <summary>App 版本</summary>
    public string? AppVersion { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
