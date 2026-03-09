namespace VegettableApi.Models;

/// <summary>
/// 分頁回應包裝 — 包含資料列表 + 分頁元數據
/// </summary>
public class PaginatedResponse<T>
{
    /// <summary>目前頁面資料</summary>
    public List<T> Items { get; set; } = new();

    /// <summary>目前頁碼 (0-based)</summary>
    public int Offset { get; set; }

    /// <summary>每頁筆數</summary>
    public int Limit { get; set; }

    /// <summary>總筆數</summary>
    public int Total { get; set; }

    /// <summary>是否有下一頁</summary>
    public bool HasMore { get; set; }

    /// <summary>總頁數</summary>
    public int TotalPages => Limit > 0 ? (Total + Limit - 1) / Limit : 0;
}
