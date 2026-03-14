namespace VegettableApi.Models;

/// <summary>
/// 食譜 DTO
/// </summary>
public class RecipeDto
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public List<string> Ingredients { get; set; } = new();
    public string Difficulty { get; set; } = "medium";
    public int CookTimeMinutes { get; set; }
}
