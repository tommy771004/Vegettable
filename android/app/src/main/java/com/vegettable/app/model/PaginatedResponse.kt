package com.vegettable.app.model

import com.google.gson.annotations.SerializedName

/**
 * 分頁回應包裝 — 包含資料列表 + 分頁元數據
 */
class PaginatedResponse<T> {
    // Getters
    @SerializedName("items")
    val items: MutableList<T?>? = null

    @SerializedName("offset")
    val offset: Int = 0

    @SerializedName("limit")
    val limit: Int = 0

    @SerializedName("total")
    val total: Int = 0

    @SerializedName("hasMore")
    val isHasMore: Boolean = false

    @SerializedName("totalPages")
    val totalPages: Int = 0
}