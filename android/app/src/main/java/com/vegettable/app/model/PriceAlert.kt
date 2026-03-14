package com.vegettable.app.model

import com.google.gson.annotations.SerializedName

class PriceAlert {
    @SerializedName("id")
    val id: Int = 0

    @SerializedName("cropName")
    val cropName: String? = null

    @SerializedName("targetPrice")
    val targetPrice: Double = 0.0

    @SerializedName("condition")
    val condition: String? = null // "below" | "above"

    @SerializedName("isActive")
    val isActive: Boolean = false

    @SerializedName("lastTriggeredAt")
    val lastTriggeredAt: String? = null

    @SerializedName("createdAt")
    val createdAt: String? = null
}
