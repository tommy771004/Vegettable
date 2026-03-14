namespace VegettableApi.Models;

/// <summary>
/// 分頁回應 DTO
/// </summary>
public class PaginatedResponse<T>
{
    public List<T> Data { get; set; } = new();
    public int Total { get; set; }
    public int Offset { get; set; }
    public int Limit { get; set; }
    public int PageCount => (Total + Limit - 1) / Limit;
}
