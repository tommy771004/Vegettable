package com.vegettable.app.model

/** 畜產品行情 */
data class LivestockPrice(
    val livestockCode: String,
    val livestockName: String,
    val marketName: String,
    val avgPrice: Double,
    val upperPrice: Double,
    val lowerPrice: Double,
    val headCount: Int,
    val avgWeight: Double,
    val transDate: String,
    /** "up" | "down" | "stable" */
    val trend: String
)
