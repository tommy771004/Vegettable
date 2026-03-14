package com.vegettable.app.util

import android.graphics.Color

/**
 * 價格相關工具 — Liquid Glass 配色
 */
object PriceUtils {
    /** 公斤 → 台斤 換算比  */
    private const val KG_TO_CATTY = 0.6

    /** 零售估算倍率  */
    private const val RETAIL_MULTIPLIER = 2.5

    fun convertToCatty(kgPrice: Double): Double {
        return kgPrice * KG_TO_CATTY
    }

    fun estimateRetailPrice(wholesalePrice: Double): Double {
        return wholesalePrice * RETAIL_MULTIPLIER
    }

    fun formatPrice(price: Double): String {
        if (price == price.toInt().toDouble()) {
            return price.toInt().toString()
        }
        return String.format("%.1f", price)
    }

    /** 依 priceLevel 取得對應顏色  */
    fun getPriceLevelColor(level: String?): Int {
        if (level == null) return Color.GRAY
        when (level) {
            "very-cheap" -> return Color.parseColor("#E53935")
            "cheap" -> return Color.parseColor("#FF7043")
            "normal" -> return Color.parseColor("#42A5F5")
            "expensive" -> return Color.parseColor("#1565C0")
            else -> return Color.GRAY
        }
    }

    /** 依 priceLevel 取得背景顏色 (帶透明度)  */
    fun getPriceLevelBgColor(level: String?): Int {
        if (level == null) return Color.parseColor("#10808080")
        when (level) {
            "very-cheap" -> return Color.parseColor("#1EE53935")
            "cheap" -> return Color.parseColor("#1EFF7043")
            "normal" -> return Color.parseColor("#1E42A5F5")
            "expensive" -> return Color.parseColor("#1E1565C0")
            else -> return Color.parseColor("#10808080")
        }
    }

    /** 價格等級 → 中文標籤  */
    fun getPriceLevelLabel(level: String?): String {
        if (level == null) return ""
        when (level) {
            "very-cheap" -> return "當令便宜"
            "cheap" -> return "相對便宜"
            "normal" -> return "略偏貴"
            "expensive" -> return "相對偏貴"
            else -> return ""
        }
    }

    /** 趨勢 → 箭頭符號  */
    fun getTrendArrow(trend: String?): String {
        if (trend == null) return "→"
        when (trend) {
            "up" -> return "↑"
            "down" -> return "↓"
            else -> return "→"
        }
    }

    /** 趨勢 → 顏色  */
    fun getTrendColor(trend: String?): Int {
        if (trend == null) return Color.GRAY
        when (trend) {
            "up" -> return Color.parseColor("#E53935")
            "down" -> return Color.parseColor("#2E7D32")
            else -> return Color.parseColor("#757575")
        }
    }
}
