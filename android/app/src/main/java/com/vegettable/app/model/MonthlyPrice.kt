package com.vegettable.app.model

import com.google.gson.annotations.SerializedName

class MonthlyPrice {
    @JvmField
    @SerializedName("month")
    val month: String? = null

    @JvmField
    @SerializedName("avgPrice")
    val avgPrice: Double = 0.0

    @SerializedName("volume")
    val volume: Double = 0.0
}
