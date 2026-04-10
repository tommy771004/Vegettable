using System.ComponentModel.DataAnnotations;

namespace VegettableApi.Models;

/// <summary>
/// 提交回饋的請求格式
/// </summary>
public class SubmitFeedbackRequest
{
    /// <summary>回饋類型: bug | suggestion | other</summary>
    [Required]
    [RegularExpression("^(bug|suggestion|other)$", ErrorMessage = "feedbackType 必須為 bug、suggestion 或 other")]
    public string FeedbackType { get; set; } = "suggestion";

    /// <summary>回饋內容（10-2000 字）</summary>
    [Required]
    [MinLength(10, ErrorMessage = "回饋內容至少需要 10 個字")]
    [MaxLength(2000, ErrorMessage = "回饋內容不能超過 2000 個字")]
    public string Content { get; set; } = string.Empty;

    /// <summary>裝置識別（選填）</summary>
    [MaxLength(300)]
    public string? DeviceToken { get; set; }

    /// <summary>App 平台（選填）: ios | android</summary>
    [MaxLength(20)]
    public string? Platform { get; set; }

    /// <summary>App 版本（選填）</summary>
    [MaxLength(20)]
    public string? AppVersion { get; set; }
}

/// <summary>
/// 回饋提交結果
/// </summary>
public class FeedbackResultDto
{
    public int Id { get; set; }
    public string Message { get; set; } = "感謝您的回饋！";
    public DateTime CreatedAt { get; set; }
}
