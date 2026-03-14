package com.vegettable.app.model

import com.google.gson.annotations.SerializedName

class ProductDetail {
    @SerializedName("cropCode")
    val cropCode: String? = null

    @SerializedName("cropName")
    val cropName: String? = null

    @JvmField
    @SerializedName("aliases")
    val aliases: MutableList<String?>? = null

    @SerializedName("category")
    val category: String? = null

    @SerializedName("subCategory")
    val subCategory: String? = null

    @JvmField
    @SerializedName("avgPrice")
    val avgPrice: Double = 0.0

    @JvmField
    @SerializedName("historicalAvgPrice")
    val historicalAvgPrice: Double = 0.0

    @JvmField
    @SerializedName("priceLevel")
    val priceLevel: String? = null

    @JvmField
    @SerializedName("trend")
    val trend: String? = null

    @JvmField
    @SerializedName("dailyPrices")
    val dailyPrices: MutableList<DailyPrice?>? = null

    @JvmField
    @SerializedName("monthlyPrices")
    val monthlyPrices: MutableList<MonthlyPrice?>? = null
}
