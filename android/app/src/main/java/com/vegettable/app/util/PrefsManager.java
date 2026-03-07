package com.vegettable.app.util;

import android.content.Context;
import android.content.SharedPreferences;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * SharedPreferences 管理 — 設定、收藏、快取
 */
public class PrefsManager {

    private static final String PREFS_NAME = "vegettable_prefs";
    private static final String KEY_PRICE_UNIT = "price_unit";        // "kg" | "catty"
    private static final String KEY_SHOW_RETAIL = "show_retail";
    private static final String KEY_DARK_MODE = "dark_mode";          // "system" | "light" | "dark"
    private static final String KEY_LANGUAGE = "language";            // "zh-TW" | "en" | "vi" | "id"
    private static final String KEY_SELECTED_MARKET = "selected_market";
    private static final String KEY_FAVORITES = "favorites";
    private static final String KEY_CACHED_PRODUCTS = "cached_products";
    private static final String KEY_CACHE_TIME = "cache_time";

    private final SharedPreferences prefs;
    private final Gson gson;

    public PrefsManager(Context context) {
        prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        gson = new Gson();
    }

    // ─── Price Unit ──────────────────────────────────────────
    public String getPriceUnit() {
        return prefs.getString(KEY_PRICE_UNIT, "kg");
    }

    public void setPriceUnit(String unit) {
        prefs.edit().putString(KEY_PRICE_UNIT, unit).apply();
    }

    public boolean isShowRetailPrice() {
        return prefs.getBoolean(KEY_SHOW_RETAIL, false);
    }

    public void setShowRetailPrice(boolean show) {
        prefs.edit().putBoolean(KEY_SHOW_RETAIL, show).apply();
    }

    // ─── Dark Mode ───────────────────────────────────────────
    public String getDarkMode() {
        return prefs.getString(KEY_DARK_MODE, "system");
    }

    public void setDarkMode(String mode) {
        prefs.edit().putString(KEY_DARK_MODE, mode).apply();
    }

    // ─── Language ────────────────────────────────────────────
    public String getLanguage() {
        return prefs.getString(KEY_LANGUAGE, "zh-TW");
    }

    public void setLanguage(String lang) {
        prefs.edit().putString(KEY_LANGUAGE, lang).apply();
    }

    // ─── Market ──────────────────────────────────────────────
    public String getSelectedMarket() {
        return prefs.getString(KEY_SELECTED_MARKET, null);
    }

    public void setSelectedMarket(String market) {
        prefs.edit().putString(KEY_SELECTED_MARKET, market).apply();
    }

    // ─── Favorites ───────────────────────────────────────────
    public Set<String> getFavorites() {
        return prefs.getStringSet(KEY_FAVORITES, new HashSet<>());
    }

    public boolean isFavorite(String cropCode) {
        return getFavorites().contains(cropCode);
    }

    public void toggleFavorite(String cropCode) {
        Set<String> favs = new HashSet<>(getFavorites());
        if (favs.contains(cropCode)) {
            favs.remove(cropCode);
        } else {
            favs.add(cropCode);
        }
        prefs.edit().putStringSet(KEY_FAVORITES, favs).apply();
    }

    // ─── Offline Cache ───────────────────────────────────────
    public void cacheProducts(String json) {
        prefs.edit()
                .putString(KEY_CACHED_PRODUCTS, json)
                .putLong(KEY_CACHE_TIME, System.currentTimeMillis())
                .apply();
    }

    public String getCachedProducts() {
        return prefs.getString(KEY_CACHED_PRODUCTS, null);
    }

    public boolean isCacheStale() {
        long cacheTime = prefs.getLong(KEY_CACHE_TIME, 0);
        long oneHour = 60 * 60 * 1000L;
        return (System.currentTimeMillis() - cacheTime) > oneHour;
    }
}
