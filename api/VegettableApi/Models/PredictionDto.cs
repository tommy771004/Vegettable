namespace VegettableApi.Models;

/// <summary>
/// AI 價格預測結果
/// </summary>
public class PredictionDto
{
    public string CropName { get; set; } = string.Empty;

    /// <summary>當前均價</summary>
    public decimal CurrentPrice { get; set; }

    /// <summary>預測下週均價</summary>
    public decimal PredictedPrice { get; set; }

    /// <summary>預測變化百分比</summary>
    public decimal ChangePercent { get; set; }

    /// <summary>預測方向: up, down, stable</summary>
    public string Direction { get; set; } = "stable";

    /// <summary>信心度 0-100</summary>
    public int Confidence { get; set; }

    /// <summary>預測依據說明</summary>
    public string Reasoning { get; set; } = string.Empty;
}
