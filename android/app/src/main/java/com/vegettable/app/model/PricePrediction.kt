package com.vegettable.app.model

import com.google.gson.annotations.SerializedName

class PricePrediction {
    @SerializedName("cropName")
    val cropName: String? = null

    @SerializedName("currentPrice")
    val currentPrice: Double = 0.0

    @JvmField
    @SerializedName("predictedPrice")
    val predictedPrice: Double = 0.0

    @JvmField
    @SerializedName("changePercent")
    val changePercent: Double = 0.0

    @JvmField
    @SerializedName("direction")
    val direction: String? = null // "up" | "down" | "stable"

    @JvmField
    @SerializedName("confidence")
    val confidence: Double = 0.0

    @JvmField
    @SerializedName("reasoning")
    val reasoning: String? = null
}
