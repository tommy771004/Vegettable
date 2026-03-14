package com.vegettable.app.model

import com.google.gson.annotations.SerializedName

/** 漁產品行情 */
data class AquaticPrice(
    val fishCode: String,
    val fishName: String,
    val marketName: String,
    val avgPrice: Double,
    val upperPrice: Double,
    val lowerPrice: Double,
    val volume: Double,
    val transDate: String,
    /** "up" | "down" | "stable" */
    val trend: String
)
