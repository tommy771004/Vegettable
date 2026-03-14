namespace VegettableApi.Models;

/// <summary>
/// 季節性資訊 DTO
/// </summary>
public class SeasonalInfoDto
{
    public string CropName { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public List<int> PeakMonths { get; set; } = new();
    public string SeasonNote { get; set; } = string.Empty;
    public bool IsInSeason { get; set; }
}
