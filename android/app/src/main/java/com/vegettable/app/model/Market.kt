package com.vegettable.app.model

import com.google.gson.annotations.SerializedName

class Market {
    @SerializedName("marketCode")
    val marketCode: String? = null

    @SerializedName("marketName")
    val marketName: String? = null

    @SerializedName("region")
    val region: String? = null

    @SerializedName("address")
    val address: String? = null

    @SerializedName("latitude")
    val latitude: Double = 0.0

    @SerializedName("longitude")
    val longitude: Double = 0.0
}
