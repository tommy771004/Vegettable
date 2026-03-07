package com.vegettable.app.model;

import com.google.gson.annotations.SerializedName;

public class MarketPrice {
    @SerializedName("marketName")
    private String marketName;

    @SerializedName("cropName")
    private String cropName;

    @SerializedName("avgPrice")
    private double avgPrice;

    @SerializedName("upperPrice")
    private double upperPrice;

    @SerializedName("lowerPrice")
    private double lowerPrice;

    @SerializedName("volume")
    private double volume;

    @SerializedName("transDate")
    private String transDate;

    public String getMarketName() { return marketName; }
    public String getCropName() { return cropName; }
    public double getAvgPrice() { return avgPrice; }
    public double getUpperPrice() { return upperPrice; }
    public double getLowerPrice() { return lowerPrice; }
    public double getVolume() { return volume; }
    public String getTransDate() { return transDate; }
}
