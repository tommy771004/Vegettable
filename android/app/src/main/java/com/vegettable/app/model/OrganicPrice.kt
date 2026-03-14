package com.vegettable.app.model

/** 有機/產銷履歷蔬果行情 */
data class OrganicPrice(
    val cropCode: String,
    val cropName: String,
    val marketName: String,
    val avgPrice: Double,
    val upperPrice: Double,
    val lowerPrice: Double,
    val volume: Double,
    /** "有機" 或 "產銷履歷" */
    val certType: String,
    val transDate: String,
    /** 與一般批發均價差異 %（正值代表有機較貴） */
    val premiumPercent: Double?
)
