package com.vegettable.app.util

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson

class PrefsManager(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val gson: Gson = Gson()

    var priceUnit: String
        get() = prefs.getString(KEY_PRICE_UNIT, "kg") ?: "kg"
        set(unit) = prefs.edit().putString(KEY_PRICE_UNIT, unit).apply()

    var isShowRetailPrice: Boolean
        get() = prefs.getBoolean(KEY_SHOW_RETAIL, false)
        set(show) = prefs.edit().putBoolean(KEY_SHOW_RETAIL, show).apply()

    var darkMode: String
        get() = prefs.getString(KEY_DARK_MODE, "system") ?: "system"
        set(mode) = prefs.edit().putString(KEY_DARK_MODE, mode).apply()

    var language: String
        get() = prefs.getString(KEY_LANGUAGE, "zh-TW") ?: "zh-TW"
        set(lang) = prefs.edit().putString(KEY_LANGUAGE, lang).apply()

    var selectedMarket: String?
        get() = prefs.getString(KEY_SELECTED_MARKET, null)
        set(market) = prefs.edit().putString(KEY_SELECTED_MARKET, market).apply()

    val favorites: Set<String>
        get() = prefs.getStringSet(KEY_FAVORITES, emptySet()) ?: emptySet()

    fun isFavorite(cropCode: String): Boolean = favorites.contains(cropCode)

    fun toggleFavorite(cropCode: String) {
        val favs = favorites.toMutableSet()
        if (favs.contains(cropCode)) {
            favs.remove(cropCode)
        } else {
            favs.add(cropCode)
        }
        prefs.edit().putStringSet(KEY_FAVORITES, favs).apply()
    }

    fun cacheProducts(json: String?) {
        prefs.edit()
            .putString(KEY_CACHED_PRODUCTS, json)
            .putLong(KEY_CACHE_TIME, System.currentTimeMillis())
            .apply()
    }

    fun clearCache() {
        prefs.edit()
            .remove(KEY_CACHED_PRODUCTS)
            .remove(KEY_CACHE_TIME)
            .apply()
    }

    val cachedProducts: String?
        get() = prefs.getString(KEY_CACHED_PRODUCTS, null)

    val isCacheStale: Boolean
        get() {
            val cacheTime = prefs.getLong(KEY_CACHE_TIME, 0)
            val oneHour = 60 * 60 * 1000L
            return (System.currentTimeMillis() - cacheTime) > oneHour
        }

    /** 快取存入時間（毫秒），0 表示無快取 */
    val cacheTimeMs: Long
        get() = prefs.getLong(KEY_CACHE_TIME, 0)

    /** 快取年齡的人性化描述，例如「3 小時前」「剛才」 */
    val cacheAgeText: String
        get() {
            val savedAt = cacheTimeMs
            if (savedAt == 0L) return "無快取"
            val mins = (System.currentTimeMillis() - savedAt) / (1000 * 60)
            return when {
                mins < 1 -> "剛才"
                mins < 60 -> "${mins} 分鐘前"
                else -> "${mins / 60} 小時前"
            }
        }

    // ─── 搜尋歷史（最多保留 5 筆）────────────────────────────

    fun getSearchHistory(): List<String> {
        val json = prefs.getString(KEY_SEARCH_HISTORY, null) ?: return emptyList()
        return try {
            gson.fromJson(json, Array<String>::class.java).toList()
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun addSearchHistory(keyword: String) {
        if (keyword.isBlank()) return
        val history = getSearchHistory().toMutableList()
        history.remove(keyword)           // 避免重複，移到最前
        history.add(0, keyword)
        val trimmed = history.take(5)     // 只保留最新 5 筆
        prefs.edit().putString(KEY_SEARCH_HISTORY, gson.toJson(trimmed)).apply()
    }

    fun clearSearchHistory() {
        prefs.edit().remove(KEY_SEARCH_HISTORY).apply()
    }

    /** 取得或建立持久化裝置識別碼（用於警示 API） */
    fun getDeviceToken(): String {
        var token = prefs.getString(KEY_DEVICE_TOKEN, null)
        if (token == null) {
            token = "android-${java.util.UUID.randomUUID()}"
            prefs.edit().putString(KEY_DEVICE_TOKEN, token).apply()
        }
        return token
    }

    companion object {
        private const val PREFS_NAME = "vegettable_prefs"
        private const val KEY_PRICE_UNIT = "price_unit"
        private const val KEY_SHOW_RETAIL = "show_retail"
        private const val KEY_DARK_MODE = "dark_mode"
        private const val KEY_LANGUAGE = "language"
        private const val KEY_SELECTED_MARKET = "selected_market"
        private const val KEY_FAVORITES = "favorites"
        private const val KEY_CACHED_PRODUCTS = "cached_products"
        private const val KEY_CACHE_TIME = "cache_time"
        private const val KEY_DEVICE_TOKEN = "device_token"
        private const val KEY_SEARCH_HISTORY = "search_history"
    }
}