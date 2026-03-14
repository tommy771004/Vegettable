package com.vegettable.app.model

import com.google.gson.annotations.SerializedName

class MarketPrice {
    @JvmField
    @SerializedName("marketName")
    val marketName: String? = null

    @SerializedName("cropName")
    val cropName: String? = null

    @JvmField
    @SerializedName("avgPrice")
    val avgPrice: Double = 0.0

    @JvmField
    @SerializedName("upperPrice")
    val upperPrice: Double = 0.0

    @JvmField
    @SerializedName("lowerPrice")
    val lowerPrice: Double = 0.0

    @SerializedName("volume")
    val volume: Double = 0.0

    @JvmField
    @SerializedName("transDate")
    val transDate: String? = null
}
