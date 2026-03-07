package com.vegettable.app.model;

import com.google.gson.annotations.SerializedName;

public class PricePrediction {
    @SerializedName("cropName")
    private String cropName;

    @SerializedName("currentPrice")
    private double currentPrice;

    @SerializedName("predictedPrice")
    private double predictedPrice;

    @SerializedName("changePercent")
    private double changePercent;

    @SerializedName("direction")
    private String direction; // "up" | "down" | "stable"

    @SerializedName("confidence")
    private double confidence;

    @SerializedName("reasoning")
    private String reasoning;

    public String getCropName() { return cropName; }
    public double getCurrentPrice() { return currentPrice; }
    public double getPredictedPrice() { return predictedPrice; }
    public double getChangePercent() { return changePercent; }
    public String getDirection() { return direction; }
    public double getConfidence() { return confidence; }
    public String getReasoning() { return reasoning; }
}
