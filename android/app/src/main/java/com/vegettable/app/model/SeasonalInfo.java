package com.vegettable.app.model;

import com.google.gson.annotations.SerializedName;
import java.util.List;

public class SeasonalInfo {
    @SerializedName("cropName")
    private String cropName;

    @SerializedName("category")
    private String category;

    @SerializedName("peakMonths")
    private List<Integer> peakMonths;

    @SerializedName("isInSeason")
    private boolean isInSeason;

    @SerializedName("seasonNote")
    private String seasonNote;

    public String getCropName() { return cropName; }
    public String getCategory() { return category; }
    public List<Integer> getPeakMonths() { return peakMonths; }
    public boolean isInSeason() { return isInSeason; }
    public String getSeasonNote() { return seasonNote; }
}
