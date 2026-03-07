package com.vegettable.app.model;

import com.google.gson.annotations.SerializedName;

public class MonthlyPrice {
    @SerializedName("month")
    private String month;

    @SerializedName("avgPrice")
    private double avgPrice;

    @SerializedName("volume")
    private double volume;

    public String getMonth() { return month; }
    public double getAvgPrice() { return avgPrice; }
    public double getVolume() { return volume; }
}
