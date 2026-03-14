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
    }
}