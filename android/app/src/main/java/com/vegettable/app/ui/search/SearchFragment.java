package com.vegettable.app.ui.search;

import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.google.android.material.textfield.TextInputEditText;
import com.vegettable.app.R;
import com.vegettable.app.model.ApiResponse;
import com.vegettable.app.model.ProductSummary;
import com.vegettable.app.network.ApiClient;
import com.vegettable.app.ui.adapter.ProductAdapter;
import com.vegettable.app.ui.detail.DetailActivity;
import com.vegettable.app.util.PrefsManager;

import java.util.List;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class SearchFragment extends Fragment implements ProductAdapter.OnItemClickListener {

    private TextInputEditText etSearch;
    private RecyclerView rvResults;
    private TextView tvResultCount;
    private TextView tvSearchError;
    private SwipeRefreshLayout swipeRefresh;
    private ProductAdapter adapter;
    private PrefsManager prefs;
    private final android.os.Handler handler = new android.os.Handler(android.os.Looper.getMainLooper());
    private Runnable searchRunnable;
    private Call<ApiResponse<List<ProductSummary>>> currentSearchCall;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_search, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        prefs = new PrefsManager(requireContext());

        etSearch = view.findViewById(R.id.et_search);
        rvResults = view.findViewById(R.id.rv_results);
        tvResultCount = view.findViewById(R.id.tv_result_count);
        tvSearchError = view.findViewById(R.id.tv_search_error);
        swipeRefresh = view.findViewById(R.id.swipe_refresh);

        rvResults.setLayoutManager(new LinearLayoutManager(requireContext()));
        adapter = new ProductAdapter(this, prefs.getFavorites());
        adapter.setPriceUnit(prefs.getPriceUnit());
        rvResults.setAdapter(adapter);

        swipeRefresh.setColorSchemeResources(R.color.primary);
        swipeRefresh.setOnRefreshListener(() -> {
            String kw = etSearch.getText() != null ? etSearch.getText().toString().trim() : "";
            if (!kw.isEmpty()) {
                performSearch(kw);
            } else {
                swipeRefresh.setRefreshing(false);
            }
        });

        // 搜尋防抖
        etSearch.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {}

            @Override
            public void afterTextChanged(Editable s) {
                if (searchRunnable != null) handler.removeCallbacks(searchRunnable);
                searchRunnable = () -> performSearch(s.toString().trim());
                handler.postDelayed(searchRunnable, 300);
            }
        });
    }

    private void performSearch(String keyword) {
        if (keyword.isEmpty()) {
            adapter.setItems(java.util.Collections.emptyList());
            tvResultCount.setVisibility(View.GONE);
            return;
        }

        // 取消前一次尚未完成的搜尋請求
        if (currentSearchCall != null) {
            currentSearchCall.cancel();
        }

        if (tvSearchError != null) tvSearchError.setVisibility(View.GONE);

        currentSearchCall = ApiClient.getInstance().getApi().searchProducts(keyword);
        currentSearchCall.enqueue(new Callback<ApiResponse<List<ProductSummary>>>() {
                    @Override
                    public void onResponse(@NonNull Call<ApiResponse<List<ProductSummary>>> call,
                                           @NonNull Response<ApiResponse<List<ProductSummary>>> response) {
                        if (!isAdded()) return;
                        swipeRefresh.setRefreshing(false);
                        if (response.isSuccessful() && response.body() != null
                                && response.body().isSuccess() && response.body().getData() != null) {
                            List<ProductSummary> results = response.body().getData();
                            adapter.setItems(results);
                            tvResultCount.setText("找到 " + results.size() + " 項結果");
                            tvResultCount.setVisibility(View.VISIBLE);
                            if (tvSearchError != null) tvSearchError.setVisibility(View.GONE);
                        }
                    }

                    @Override
                    public void onFailure(@NonNull Call<ApiResponse<List<ProductSummary>>> call,
                                          @NonNull Throwable t) {
                        if (!isAdded()) return;
                        swipeRefresh.setRefreshing(false);
                        if (tvSearchError != null) {
                            tvSearchError.setText("搜尋失敗: " + t.getMessage());
                            tvSearchError.setVisibility(View.VISIBLE);
                        }
                    }
                });
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
        adapter.notifyItemRangeChanged(0, adapter.getItemCount());
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        if (searchRunnable != null) {
            handler.removeCallbacks(searchRunnable);
        }
        if (currentSearchCall != null) {
            currentSearchCall.cancel();
        }
    }
}
