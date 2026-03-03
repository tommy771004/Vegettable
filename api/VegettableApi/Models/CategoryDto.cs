namespace VegettableApi.Models;

/// <summary>
/// 類別資訊
/// </summary>
public class CategoryDto
{
    public string Key { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty;
    public List<SubCategoryDto>? SubCategories { get; set; }
}

/// <summary>
/// 子類別資訊
/// </summary>
public class SubCategoryDto
{
    public string Key { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty;
}
