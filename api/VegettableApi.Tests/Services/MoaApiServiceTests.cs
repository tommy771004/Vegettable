using FluentAssertions;
using Xunit;

namespace VegettableApi.Tests.Services;

/// <summary>
/// MoaApiService 靜態邏輯測試（不呼叫真實 API，使用反射驗證民國年換算）
/// </summary>
public class MoaApiServiceTests
{
    [Theory]
    [InlineData(2024, 1, 15, "113.01.15")]
    [InlineData(2025, 3, 9, "114.03.09")]
    [InlineData(2023, 12, 31, "112.12.31")]
    [InlineData(1912, 1, 1, "1.01.01")]
    public void ToRocDate_ShouldConvertCorrectly(int year, int month, int day, string expected)
    {
        var method = typeof(VegettableApi.Services.MoaApiService)
            .GetMethod("ToRocDate",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static);

        method.Should().NotBeNull("ToRocDate private static 方法應存在");

        var result = method!.Invoke(null, new object[] { new DateTime(year, month, day) });
        result.Should().Be(expected);
    }
}