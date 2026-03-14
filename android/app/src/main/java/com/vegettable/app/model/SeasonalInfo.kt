package com.vegettable.app.model

import com.google.gson.annotations.SerializedName

class SeasonalInfo {
    @JvmField
    @SerializedName("cropName")
    val cropName: String? = null

    @SerializedName("category")
    val category: String? = null

    @JvmField
    @SerializedName("peakMonths")
    val peakMonths: MutableList<Int?>? = null

    @JvmField
    @SerializedName("isInSeason")
    val isInSeason: Boolean = false

    @JvmField
    @SerializedName("seasonNote")
    val seasonNote: String? = null
}
