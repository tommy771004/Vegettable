package com.vegettable.app.model;

import com.google.gson.annotations.SerializedName;
import java.util.List;

public class ProductDetail {
    @SerializedName("cropCode")
    private String cropCode;

    @SerializedName("cropName")
    private String cropName;

    @SerializedName("aliases")
    private List<String> aliases;

    @SerializedName("category")
    private String category;

    @SerializedName("subCategory")
    private String subCategory;

    @SerializedName("avgPrice")
    private double avgPrice;

    @SerializedName("historicalAvgPrice")
    private double historicalAvgPrice;

    @SerializedName("priceLevel")
    private String priceLevel;

    @SerializedName("trend")
    private String trend;

    @SerializedName("dailyPrices")
    private List<DailyPrice> dailyPrices;

    @SerializedName("monthlyPrices")
    private List<MonthlyPrice> monthlyPrices;

    public String getCropCode() { return cropCode; }
    public String getCropName() { return cropName; }
    public List<String> getAliases() { return aliases; }
    public String getCategory() { return category; }
    public String getSubCategory() { return subCategory; }
    public double getAvgPrice() { return avgPrice; }
    public double getHistoricalAvgPrice() { return historicalAvgPrice; }
    public String getPriceLevel() { return priceLevel; }
    public String getTrend() { return trend; }
    public List<DailyPrice> getDailyPrices() { return dailyPrices; }
    public List<MonthlyPrice> getMonthlyPrices() { return monthlyPrices; }
}
