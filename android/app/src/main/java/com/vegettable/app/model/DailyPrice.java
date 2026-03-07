package com.vegettable.app.model;

import com.google.gson.annotations.SerializedName;

public class DailyPrice {
    @SerializedName("date")
    private String date;

    @SerializedName("avgPrice")
    private double avgPrice;

    @SerializedName("volume")
    private double volume;

    public String getDate() { return date; }
    public double getAvgPrice() { return avgPrice; }
    public double getVolume() { return volume; }
}
