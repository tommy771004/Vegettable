package com.vegettable.app.model;

import com.google.gson.annotations.SerializedName;

public class PriceAlert {
    @SerializedName("id")
    private int id;

    @SerializedName("cropName")
    private String cropName;

    @SerializedName("targetPrice")
    private double targetPrice;

    @SerializedName("condition")
    private String condition; // "below" | "above"

    @SerializedName("isActive")
    private boolean isActive;

    @SerializedName("lastTriggeredAt")
    private String lastTriggeredAt;

    @SerializedName("createdAt")
    private String createdAt;

    public int getId() { return id; }
    public String getCropName() { return cropName; }
    public double getTargetPrice() { return targetPrice; }
    public String getCondition() { return condition; }
    public boolean isActive() { return isActive; }
    public String getLastTriggeredAt() { return lastTriggeredAt; }
    public String getCreatedAt() { return createdAt; }
}
