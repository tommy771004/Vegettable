using System.ComponentModel.DataAnnotations;

namespace VegettableApi.Models;

/// <summary>
/// 價格警示 DTO — 前端用
/// </summary>
public class PriceAlertDto
{
    public int Id { get; set; }
    public string CropName { get; set; } = string.Empty;
    public decimal TargetPrice { get; set; }
    public string Condition { get; set; } = "below";
    public bool IsActive { get; set; } = true;
    public DateTime? LastTriggeredAt { get; set; }
    public DateTime CreatedAt { get; set; }
}

/// <summary>
/// 建立警示的請求
/// </summary>
public class CreateAlertRequest
{
    [Required(ErrorMessage = "請提供 deviceToken")]
    [StringLength(300, MinimumLength = 20, ErrorMessage = "deviceToken 長度無效")]
    public string DeviceToken { get; set; } = string.Empty;

    [Required(ErrorMessage = "請提供作物名稱")]
    [StringLength(50, MinimumLength = 1, ErrorMessage = "作物名稱長度無效")]
    public string CropName { get; set; } = string.Empty;

    [Range(0.01, 100000, ErrorMessage = "目標價格須介於 0.01 到 100000 之間")]
    public decimal TargetPrice { get; set; }

    [Required(ErrorMessage = "請提供條件")]
    [RegularExpression("^(below|above)$", ErrorMessage = "條件只能是 below 或 above")]
    public string Condition { get; set; } = "below";
}
