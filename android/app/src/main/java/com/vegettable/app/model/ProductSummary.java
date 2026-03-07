package com.vegettable.app.model;

import com.google.gson.annotations.SerializedName;
import java.util.List;

public class ProductSummary {
    @SerializedName("cropCode")
    private String cropCode;

    @SerializedName("cropName")
    private String cropName;

    @SerializedName("avgPrice")
    private double avgPrice;

    @SerializedName("prevAvgPrice")
    private double prevAvgPrice;

    @SerializedName("historicalAvgPrice")
    private double historicalAvgPrice;

    @SerializedName("volume")
    private double volume;

    @SerializedName("priceLevel")
    private String priceLevel;

    @SerializedName("trend")
    private String trend;

    @SerializedName("recentPrices")
    private List<DailyPrice> recentPrices;

    @SerializedName("category")
    private String category;

    @SerializedName("subCategory")
    private String subCategory;

    @SerializedName("aliases")
    private List<String> aliases;

    // Getters
    public String getCropCode() { return cropCode; }
    public String getCropName() { return cropName; }
    public double getAvgPrice() { return avgPrice; }
    public double getPrevAvgPrice() { return prevAvgPrice; }
    public double getHistoricalAvgPrice() { return historicalAvgPrice; }
    public double getVolume() { return volume; }
    public String getPriceLevel() { return priceLevel; }
    public String getTrend() { return trend; }
    public List<DailyPrice> getRecentPrices() { return recentPrices; }
    public String getCategory() { return category; }
    public String getSubCategory() { return subCategory; }
    public List<String> getAliases() { return aliases; }
}
