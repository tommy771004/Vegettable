package com.vegettable.app.model;

import com.google.gson.annotations.SerializedName;

public class CreateAlertRequest {
    @SerializedName("deviceToken")
    private String deviceToken;

    @SerializedName("cropName")
    private String cropName;

    @SerializedName("targetPrice")
    private double targetPrice;

    @SerializedName("condition")
    private String condition;

    public CreateAlertRequest(String deviceToken, String cropName, double targetPrice, String condition) {
        this.deviceToken = deviceToken;
        this.cropName = cropName;
        this.targetPrice = targetPrice;
        this.condition = condition;
    }
}
