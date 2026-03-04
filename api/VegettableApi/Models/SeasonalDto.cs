namespace VegettableApi.Models;

/// <summary>
/// 季節性資訊 — 各品項的盛產月份
/// </summary>
public class SeasonalInfoDto
{
    public string CropName { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;

    /// <summary>盛產月份清單 (1-12)</summary>
    public List<int> PeakMonths { get; set; } = new();

    /// <summary>是否為當季</summary>
    public bool IsInSeason { get; set; }

    /// <summary>品質描述</summary>
    public string SeasonNote { get; set; } = string.Empty;
}
