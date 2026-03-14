namespace VegettableApi.Models;

/// <summary>
/// 產品分類 DTO
/// </summary>
public class CategoryDto
{
    public string Category { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public int Count { get; set; }
}
