using VegettableApi.Models;

namespace VegettableApi.Services;

/// <summary>
/// 農業部開放資料 API 服務介面
/// </summary>
public interface IMoaApiService
{
    /// <summary>
    /// 取得農產品交易行情原始資料
    /// </summary>
    /// <param name="startDate">起始日期 (西元)</param>
    /// <param name="endDate">結束日期 (西元)</param>
    /// <param name="cropName">作物名稱 (可選)</param>
    /// <param name="market">市場名稱 (可選)</param>
    /// <param name="top">最多回傳筆數</param>
    /// <param name="skip">略過筆數</param>
    Task<List<MoaRawData>> FetchFarmTransDataAsync(
        DateTime? startDate = null,
        DateTime? endDate = null,
        string? cropName = null,
        string? market = null,
        int top = 20000,
        int skip = 0);
}
