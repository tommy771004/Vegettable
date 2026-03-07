package com.vegettable.app.model;

import com.google.gson.annotations.SerializedName;

public class Market {
    @SerializedName("marketCode")
    private String marketCode;

    @SerializedName("marketName")
    private String marketName;

    @SerializedName("region")
    private String region;

    public String getMarketCode() { return marketCode; }
    public String getMarketName() { return marketName; }
    public String getRegion() { return region; }
}
