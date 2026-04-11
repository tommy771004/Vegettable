package com.vegettable.app.model

/** 毛豬行情 (肉品市場) */
data class AnimalPrice(
    val productCode: String,
    val productName: String,
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
