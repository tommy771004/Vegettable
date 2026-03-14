namespace VegettableApi.Models;

/// <summary>
/// 價格預測結果 DTO
/// </summary>
public class PredictionDto
{
    public string CropName { get; set; } = string.Empty;
    public decimal CurrentPrice { get; set; }
    public decimal PredictedPrice { get; set; }
    public decimal ChangePercent { get; set; }
    public string Direction { get; set; } = "stable";
    public int Confidence { get; set; }
    public string Reasoning { get; set; } = string.Empty;
}
