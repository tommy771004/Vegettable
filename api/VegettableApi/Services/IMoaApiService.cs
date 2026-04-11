using VegettableApi.Models;

namespace VegettableApi.Services;

/// <summary>
/// 農業部開放資料 API 服務介面
/// </summary>
public interface IMoaApiService
{
    /// <summary>取得農產品（蔬果）交易行情 (FarmTransData)</summary>
    Task<List<MoaRawData>> FetchFarmTransDataAsync(
        DateTime? startDate = null,
        DateTime? endDate = null,
        string? cropName = null,
        string? market = null,
        int top = 20000,
        int skip = 0);

    /// <summary>取得漁產品交易行情 (AquaticTransData)</summary>
    Task<List<AquaticRawData>> FetchAquaticTransDataAsync(
        DateTime? startDate = null,
        DateTime? endDate = null,
        string? fishName = null,
        string? market = null,
        int top = 10000);

    /// <summary>取得畜產品交易行情 (LivestockTransData)</summary>
    Task<List<LivestockRawData>> FetchLivestockTransDataAsync(
        DateTime? startDate = null,
        DateTime? endDate = null,
        string? livestockName = null,
        int top = 10000);

    /// <summary>取得產銷履歷與有機蔬果行情 (TAPData)</summary>
    Task<List<OrganicRawData>> FetchOrganicTransDataAsync(
        DateTime? startDate = null,
        DateTime? endDate = null,
        string? cropName = null,
        int top = 10000);

    /// <summary>取得花卉交易行情 (FlowerData)</summary>
    Task<List<FlowerRawData>> FetchFlowerTransDataAsync(
        DateTime? startDate = null,
        DateTime? endDate = null,
        string? flowerName = null,
        string? market = null,
        int top = 10000);
}
