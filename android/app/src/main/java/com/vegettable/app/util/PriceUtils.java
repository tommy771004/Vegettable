package com.vegettable.app.util;

import android.graphics.Color;

/**
 * 價格相關工具
 */
public class PriceUtils {

    /** 公斤 → 台斤 換算比 */
    private static final double KG_TO_CATTY = 0.6;

    /** 零售估算倍率 */
    private static final double RETAIL_MULTIPLIER = 2.5;

    public static double convertToCatty(double kgPrice) {
        return kgPrice * KG_TO_CATTY;
    }

    public static double estimateRetailPrice(double wholesalePrice) {
        return wholesalePrice * RETAIL_MULTIPLIER;
    }

    public static String formatPrice(double price) {
        if (price == (int) price) {
            return String.valueOf((int) price);
        }
        return String.format("%.1f", price);
    }

    /** 依 priceLevel 取得對應顏色 */
    public static int getPriceLevelColor(String level) {
        if (level == null) return Color.GRAY;
        switch (level) {
            case "very-cheap": return Color.parseColor("#D32F2F");
            case "cheap":      return Color.parseColor("#FF8A80");
            case "normal":     return Color.parseColor("#82B1FF");
            case "expensive":  return Color.parseColor("#1565C0");
            default:           return Color.GRAY;
        }
    }

    /** 依 priceLevel 取得背景顏色 (帶透明度) */
    public static int getPriceLevelBgColor(String level) {
        if (level == null) return Color.parseColor("#10808080");
        switch (level) {
            case "very-cheap": return Color.parseColor("#1AD32F2F");
            case "cheap":      return Color.parseColor("#1AFF8A80");
            case "normal":     return Color.parseColor("#1A82B1FF");
            case "expensive":  return Color.parseColor("#1A1565C0");
            default:           return Color.parseColor("#10808080");
        }
    }

    /** 價格等級 → 中文標籤 */
    public static String getPriceLevelLabel(String level) {
        if (level == null) return "";
        switch (level) {
            case "very-cheap": return "當令便宜";
            case "cheap":      return "相對便宜";
            case "normal":     return "略偏貴";
            case "expensive":  return "相對偏貴";
            default:           return "";
        }
    }

    /** 趨勢 → 箭頭符號 */
    public static String getTrendArrow(String trend) {
        if (trend == null) return "→";
        switch (trend) {
            case "up":   return "↑";
            case "down": return "↓";
            default:     return "→";
        }
    }

    /** 趨勢 → 顏色 */
    public static int getTrendColor(String trend) {
        if (trend == null) return Color.GRAY;
        switch (trend) {
            case "up":   return Color.parseColor("#D32F2F");
            case "down": return Color.parseColor("#2E7D32");
            default:     return Color.parseColor("#757575");
        }
    }
}
