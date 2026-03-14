package com.vegettable.app.network

import com.vegettable.app.model.ApiResponse
import com.vegettable.app.model.CreateAlertRequest
import com.vegettable.app.model.Market
import com.vegettable.app.model.MarketPrice
import com.vegettable.app.model.PriceAlert
import com.vegettable.app.model.PricePrediction
import com.vegettable.app.model.ProductDetail
import com.vegettable.app.model.ProductSummary
import com.vegettable.app.model.Recipe
import com.vegettable.app.model.SeasonalInfo
import retrofit2.Call
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.PATCH
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query

/**
 * Retrofit API 介面 — 對應 .NET 後端所有端點
 */
interface ApiService {
    // ─── Products ────────────────────────────────────────────
    @GET("/api/products")
    fun getProducts(
        @Query("category") category: String?
    ): Call<ApiResponse<MutableList<ProductSummary?>?>?>?

    @GET("/api/products/search")
    fun searchProducts(
        @Query("keyword") keyword: String?
    ): Call<ApiResponse<MutableList<ProductSummary?>?>?>?

    @GET("/api/products/{cropName}")
    fun getProductDetail(
        @Path("cropName") cropName: String?
    ): Call<ApiResponse<ProductDetail?>?>?

    @get:GET("/api/markets")
    val markets: Call<ApiResponse<MutableList<Market?>?>?>?

    @GET("/api/markets/{marketName}/prices")
    fun getMarketPrices(
        @Path("marketName") marketName: String?,
        @Query("cropName") cropName: String?
    ): Call<ApiResponse<MutableList<MarketPrice?>?>?>?

    @GET("/api/markets/compare/{cropName}")
    fun compareMarketPrices(
        @Path("cropName") cropName: String?,
        @Query("markets") markets: String?
    ): Call<ApiResponse<MutableList<MarketPrice?>?>?>?

    // ─── Alerts ──────────────────────────────────────────────
    @GET("/api/alerts")
    fun getAlerts(
        @Query("deviceToken") deviceToken: String?
    ): Call<ApiResponse<MutableList<PriceAlert?>?>?>?

    @POST("/api/alerts")
    fun createAlert(
        @Body request: CreateAlertRequest?
    ): Call<ApiResponse<PriceAlert?>?>?

    @DELETE("/api/alerts/{id}")
    fun deleteAlert(
        @Path("id") id: Int,
        @Query("deviceToken") deviceToken: String?
    ): Call<Void?>?

    @PATCH("/api/alerts/{id}/toggle")
    fun toggleAlert(
        @Path("id") id: Int,
        @Query("deviceToken") deviceToken: String?
    ): Call<Void?>?

    // ─── Prediction / Seasonal / Recipes ─────────────────────
    @GET("/api/prediction/{cropName}")
    fun getPrediction(
        @Path("cropName") cropName: String?
    ): Call<ApiResponse<PricePrediction?>?>?

    @GET("/api/prediction/seasonal")
    fun getSeasonalInfo(
        @Query("category") category: String?
    ): Call<ApiResponse<MutableList<SeasonalInfo?>?>?>?

    @GET("/api/prediction/{cropName}/recipes")
    fun getRecipes(
        @Path("cropName") cropName: String?
    ): Call<ApiResponse<MutableList<Recipe?>?>?>?

    // ─── Health ──────────────────────────────────────────────
    @GET("/health")
    fun healthCheck(): Call<Void?>?
}
