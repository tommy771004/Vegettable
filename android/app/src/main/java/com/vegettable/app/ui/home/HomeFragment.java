package com.vegettable.app.ui.home;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.google.android.material.chip.Chip;
import com.google.android.material.chip.ChipGroup;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.vegettable.app.R;
import com.vegettable.app.model.ApiResponse;
import com.vegettable.app.model.ProductSummary;
import com.vegettable.app.network.ApiClient;
import com.vegettable.app.ui.adapter.ProductAdapter;
import com.vegettable.app.ui.detail.DetailActivity;
import com.vegettable.app.util.PrefsManager;

import com.vegettable.app.model.PaginatedResponse;

import java.util.ArrayList;
import java.util.List;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class HomeFragment extends Fragment implements ProductAdapter.OnItemClickListener {

    private RecyclerView rvProducts;
    private ProgressBar progressBar;
    private LinearLayout layoutError;
    private TextView tvError;
    private SwipeRefreshLayout swipeRefresh;
    private ChipGroup chipGroupCategory;

    private ProductAdapter adapter;
    private PrefsManager prefs;
    private String selectedCategory = null;

    // 分頁狀態
    private static final int PAGE_SIZE = 20;
    private int currentOffset = 0;
    private boolean hasMore = false;
    private boolean isLoadingMore = false;

    private static final String[][] CATEGORIES = {
            {"all", "全部"}, {"vegetable", "蔬菜"}, {"fruit", "水果"},
            {"fish", "漁產"}, {"poultry", "肉品"}, {"flower", "花卉"}, {"rice", "白米"}
    };

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_home, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        prefs = new PrefsManager(requireContext());

        rvProducts = view.findViewById(R.id.rv_products);
        progressBar = view.findViewById(R.id.progress_bar);
        layoutError = view.findViewById(R.id.layout_error);
        tvError = view.findViewById(R.id.tv_error);
        swipeRefresh = view.findViewById(R.id.swipe_refresh);
        chipGroupCategory = view.findViewById(R.id.chip_group_category);

        // 設定 RecyclerView
        LinearLayoutManager layoutManager = new LinearLayoutManager(requireContext());
        rvProducts.setLayoutManager(layoutManager);
        adapter = new ProductAdapter(this, prefs.getFavorites());
        adapter.setPriceUnit(prefs.getPriceUnit());
        adapter.setShowRetail(prefs.isShowRetailPrice());
        rvProducts.setAdapter(adapter);

        // Infinite scroll — 接近底部時自動載入下一頁
        rvProducts.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrolled(@NonNull RecyclerView recyclerView, int dx, int dy) {
                if (dy <= 0) return; // 只在向下滾動時觸發
                int visibleCount = layoutManager.getChildCount();
                int totalCount = layoutManager.getItemCount();
                int firstVisible = layoutManager.findFirstVisibleItemPosition();

                if (hasMore && !isLoadingMore && (visibleCount + firstVisible + 5) >= totalCount) {
                    loadMoreProducts();
                }
            }
        });

        // 分類 Chips
        setupCategoryChips();

        // 下拉刷新
        swipeRefresh.setColorSchemeResources(R.color.primary);
        swipeRefresh.setOnRefreshListener(this::loadProducts);

        // 重試按鈕
        view.findViewById(R.id.btn_retry).setOnClickListener(v -> loadProducts());

        // 載入資料
        loadProducts();
    }

    private void setupCategoryChips() {
        for (String[] cat : CATEGORIES) {
            Chip chip = new Chip(requireContext());
            chip.setText(cat[1]);
            chip.setCheckable(true);
            chip.setTag(cat[0]);
            if ("all".equals(cat[0])) {
                chip.setChecked(true);
            }
            chip.setOnCheckedChangeListener((buttonView, isChecked) -> {
                if (isChecked) {
                    String tag = (String) buttonView.getTag();
                    selectedCategory = "all".equals(tag) ? null : tag;
                    loadProducts();
                }
            });
            chipGroupCategory.addView(chip);
        }
    }

    private void loadProducts() {
        progressBar.setVisibility(View.VISIBLE);
        layoutError.setVisibility(View.GONE);
        currentOffset = 0;

        ApiClient.getInstance().getApi().getProductsPaginated(selectedCategory, 0, PAGE_SIZE)
                .enqueue(new Callback<ApiResponse<PaginatedResponse<ProductSummary>>>() {
                    @Override
                    public void onResponse(@NonNull Call<ApiResponse<PaginatedResponse<ProductSummary>>> call,
                                           @NonNull Response<ApiResponse<PaginatedResponse<ProductSummary>>> response) {
                        if (!isAdded()) return;
                        swipeRefresh.setRefreshing(false);
                        progressBar.setVisibility(View.GONE);

                        if (response.isSuccessful() && response.body() != null
                                && response.body().isSuccess() && response.body().getData() != null) {
                            PaginatedResponse<ProductSummary> page = response.body().getData();
                            List<ProductSummary> products = page.getItems();
                            adapter.setItems(products);
                            hasMore = page.isHasMore();
                            currentOffset = products.size();
                            rvProducts.setVisibility(View.VISIBLE);

                            // 快取
                            prefs.cacheProducts(new Gson().toJson(products));
                        } else {
                            showError("無法取得資料");
                            loadCachedProducts();
                        }
                    }

                    @Override
                    public void onFailure(@NonNull Call<ApiResponse<PaginatedResponse<ProductSummary>>> call,
                                          @NonNull Throwable t) {
                        if (!isAdded()) return;
                        swipeRefresh.setRefreshing(false);
                        progressBar.setVisibility(View.GONE);
                        showError("網路錯誤: " + t.getMessage());
                        loadCachedProducts();
                    }
                });
    }

    private void loadMoreProducts() {
        if (!hasMore || isLoadingMore) return;
        isLoadingMore = true;

        ApiClient.getInstance().getApi().getProductsPaginated(selectedCategory, currentOffset, PAGE_SIZE)
                .enqueue(new Callback<ApiResponse<PaginatedResponse<ProductSummary>>>() {
                    @Override
                    public void onResponse(@NonNull Call<ApiResponse<PaginatedResponse<ProductSummary>>> call,
                                           @NonNull Response<ApiResponse<PaginatedResponse<ProductSummary>>> response) {
                        isLoadingMore = false;
                        if (!isAdded()) return;

                        if (response.isSuccessful() && response.body() != null
                                && response.body().isSuccess() && response.body().getData() != null) {
                            PaginatedResponse<ProductSummary> page = response.body().getData();
                            List<ProductSummary> newItems = page.getItems();
                            adapter.addItems(newItems);
                            hasMore = page.isHasMore();
                            currentOffset += newItems.size();
                        }
                    }

                    @Override
                    public void onFailure(@NonNull Call<ApiResponse<PaginatedResponse<ProductSummary>>> call,
                                          @NonNull Throwable t) {
                        isLoadingMore = false;
                    }
                });
    }

    private void loadCachedProducts() {
        String cached = prefs.getCachedProducts();
        if (cached != null) {
            try {
                List<ProductSummary> products = new Gson().fromJson(cached,
                        new TypeToken<List<ProductSummary>>(){}.getType());
                if (products != null && !products.isEmpty()) {
                    adapter.setItems(products);
                    rvProducts.setVisibility(View.VISIBLE);
                    layoutError.setVisibility(View.GONE);
                }
            } catch (Exception ignored) {}
        }
    }

    private void showError(String message) {
        tvError.setText(message);
        layoutError.setVisibility(View.VISIBLE);
    }

    @Override
    public void onItemClick(ProductSummary product) {
        Intent intent = new Intent(requireContext(), DetailActivity.class);
        intent.putExtra("cropName", product.getCropName());
        intent.putExtra("cropCode", product.getCropCode());
        startActivity(intent);
    }

    @Override
    public void onFavoriteClick(ProductSummary product) {
        prefs.toggleFavorite(product.getCropCode());
        // 只更新被點擊的項目，而非整個列表
        adapter.notifyItemRangeChanged(0, adapter.getItemCount());
    }

    @Override
    public void onResume() {
        super.onResume();
        // 更新收藏狀態和設定
        if (adapter != null) {
            adapter.setPriceUnit(prefs.getPriceUnit());
            adapter.setShowRetail(prefs.isShowRetailPrice());
        }
    }
}
