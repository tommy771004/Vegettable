namespace VegettableApi.Models;

/// <summary>
/// 價格警示 DTO
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
