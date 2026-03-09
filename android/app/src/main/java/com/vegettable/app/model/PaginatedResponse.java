package com.vegettable.app.model;

import com.google.gson.annotations.SerializedName;
import java.util.List;

/**
 * 分頁回應包裝 — 包含資料列表 + 分頁元數據
 */
public class PaginatedResponse<T> {
    @SerializedName("items")
    private List<T> items;

    @SerializedName("offset")
    private int offset;

    @SerializedName("limit")
    private int limit;

    @SerializedName("total")
    private int total;

    @SerializedName("hasMore")
    private boolean hasMore;

    @SerializedName("totalPages")
    private int totalPages;

    // Getters
    public List<T> getItems() { return items; }
    public int getOffset() { return offset; }
    public int getLimit() { return limit; }
    public int getTotal() { return total; }
    public boolean isHasMore() { return hasMore; }
    public int getTotalPages() { return totalPages; }
}
