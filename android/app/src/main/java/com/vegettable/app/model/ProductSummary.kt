package com.vegettable.app.model

import com.google.gson.annotations.SerializedName

class ProductSummary {
    // Getters
    @JvmField
    @SerializedName("cropCode")
    val cropCode: String? = null

    @JvmField
    @SerializedName("cropName")
    val cropName: String? = null

    @JvmField
    @SerializedName("avgPrice")
    val avgPrice: Double = 0.0

    @SerializedName("prevAvgPrice")
    val prevAvgPrice: Double = 0.0

    @SerializedName("historicalAvgPrice")
    val historicalAvgPrice: Double = 0.0

    @SerializedName("volume")
    val volume: Double = 0.0

    @JvmField
    @SerializedName("priceLevel")
    val priceLevel: String? = null

    @JvmField
    @SerializedName("trend")
    val trend: String? = null

    @SerializedName("recentPrices")
    val recentPrices: MutableList<DailyPrice?>? = null

    @SerializedName("category")
    val category: String? = null

    @SerializedName("subCategory")
    val subCategory: String? = null

    @JvmField
    @SerializedName("aliases")
    val aliases: MutableList<String?>? = null
}
