using FluentAssertions;
using VegettableApi.Models;
using Xunit;

namespace VegettableApi.Tests.Models;

public class ProductDetailDtoTests
{
    [Fact]
    public void ProductDetailDto_DefaultPriceLevel_ShouldBeNormal()
    {
        var dto = new ProductDetailDto();
        dto.PriceLevel.Should().Be("normal");
    }

    [Fact]
    public void ProductDetailDto_DefaultTrend_ShouldBeStable()
    {
        var dto = new ProductDetailDto();
        dto.Trend.Should().Be("stable");
    }

    [Fact]
    public void ProductDetailDto_DailyPrices_ShouldBeInitialized()
    {
        var dto = new ProductDetailDto();
        dto.DailyPrices.Should().NotBeNull();
        dto.DailyPrices.Should().BeEmpty();
    }

    [Fact]
    public void ProductDetailDto_MonthlyPrices_ShouldBeInitialized()
    {
        var dto = new ProductDetailDto();
        dto.MonthlyPrices.Should().NotBeNull();
        dto.MonthlyPrices.Should().BeEmpty();
    }

    [Fact]
    public void ProductDetailDto_Aliases_ShouldBeInitialized()
    {
        var dto = new ProductDetailDto();
        dto.Aliases.Should().NotBeNull();
        dto.Aliases.Should().BeEmpty();
    }

    [Fact]
    public void ProductDetailDto_DefaultAvgPrice_ShouldBeZero()
    {
        var dto = new ProductDetailDto();
        dto.AvgPrice.Should().Be(0);
    }
}