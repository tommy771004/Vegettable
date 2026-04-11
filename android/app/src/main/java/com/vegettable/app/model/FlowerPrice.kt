package com.vegettable.app.model

/** 花卉行情 */
data class FlowerPrice(
    val flowerCode: String,
    val flowerName: String,
    val flowerType: String,
    val marketName: String,
    val avgPrice: Double,
    val upperPrice: Double,
    val lowerPrice: Double,
    val volume: Double,
    val transDate: String,
    /** "up" | "down" | "stable" */
    val trend: String
)
