package com.vegettable.app.network;

import com.vegettable.app.model.*;

import java.util.List;

import retrofit2.Call;
import retrofit2.http.*;

/**
 * Retrofit API 介面 — 對應 .NET 後端所有端點
 */
public interface ApiService {

    // ─── Products ────────────────────────────────────────────
    @GET("/api/products")
    Call<ApiResponse<List<ProductSummary>>> getProducts(
            @Query("category") String category
    );

    @GET("/api/products/paginated")
    Call<ApiResponse<PaginatedResponse<ProductSummary>>> getProductsPaginated(
            @Query("category") String category,
            @Query("offset") int offset,
            @Query("limit") int limit
    );

    @GET("/api/products/search")
    Call<ApiResponse<List<ProductSummary>>> searchProducts(
            @Query("keyword") String keyword
    );

    @GET("/api/products/search/paginated")
    Call<ApiResponse<PaginatedResponse<ProductSummary>>> searchProductsPaginated(
            @Query("keyword") String keyword,
            @Query("offset") int offset,
            @Query("limit") int limit
    );

    @GET("/api/products/{cropName}")
    Call<ApiResponse<ProductDetail>> getProductDetail(
            @Path("cropName") String cropName
    );

    // ─── Markets ─────────────────────────────────────────────
    @GET("/api/markets")
    Call<ApiResponse<List<Market>>> getMarkets();

    @GET("/api/markets/{marketName}/prices")
    Call<ApiResponse<List<MarketPrice>>> getMarketPrices(
            @Path("marketName") String marketName,
            @Query("cropName") String cropName
    );

    @GET("/api/markets/compare/{cropName}")
    Call<ApiResponse<List<MarketPrice>>> compareMarketPrices(
            @Path("cropName") String cropName,
            @Query("markets") String markets
    );

    // ─── Alerts ──────────────────────────────────────────────
    @GET("/api/alerts")
    Call<ApiResponse<List<PriceAlert>>> getAlerts(
            @Query("deviceToken") String deviceToken
    );

    @POST("/api/alerts")
    Call<ApiResponse<PriceAlert>> createAlert(
            @Body CreateAlertRequest request
    );

    @DELETE("/api/alerts/{id}")
    Call<Void> deleteAlert(
            @Path("id") int id,
            @Query("deviceToken") String deviceToken
    );

    @PATCH("/api/alerts/{id}/toggle")
    Call<Void> toggleAlert(
            @Path("id") int id,
            @Query("deviceToken") String deviceToken
    );

    // ─── Prediction / Seasonal / Recipes ─────────────────────
    @GET("/api/prediction/{cropName}")
    Call<ApiResponse<PricePrediction>> getPrediction(
            @Path("cropName") String cropName
    );

    @GET("/api/prediction/seasonal")
    Call<ApiResponse<List<SeasonalInfo>>> getSeasonalInfo(
            @Query("category") String category
    );

    @GET("/api/prediction/{cropName}/recipes")
    Call<ApiResponse<List<Recipe>>> getRecipes(
            @Path("cropName") String cropName
    );

    // ─── Health ──────────────────────────────────────────────
    @GET("/health")
    Call<Void> healthCheck();
}
