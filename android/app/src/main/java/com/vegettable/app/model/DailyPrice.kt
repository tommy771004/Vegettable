package com.vegettable.app.model

import com.google.gson.annotations.SerializedName

class DailyPrice {
    @JvmField
    @SerializedName("date")
    val date: String? = null

    @JvmField
    @SerializedName("avgPrice")
    val avgPrice: Double = 0.0

    @JvmField
    @SerializedName("volume")
    val volume: Double = 0.0
}
