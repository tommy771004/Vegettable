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
    private ProductAdapter adapter;
    private PrefsManager prefs;
    private android.os.Handler handler = new android.os.Handler();
    private Runnable searchRunnable;

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

        rvResults.setLayoutManager(new LinearLayoutManager(requireContext()));
        adapter = new ProductAdapter(this, prefs.getFavorites());
        adapter.setPriceUnit(prefs.getPriceUnit());
        rvResults.setAdapter(adapter);

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

        if (tvSearchError != null) tvSearchError.setVisibility(View.GONE);

        ApiClient.getInstance().getApi().searchProducts(keyword)
                .enqueue(new Callback<ApiResponse<List<ProductSummary>>>() {
                    @Override
                    public void onResponse(@NonNull Call<ApiResponse<List<ProductSummary>>> call,
                                           @NonNull Response<ApiResponse<List<ProductSummary>>> response) {
                        if (!isAdded()) return;
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
        adapter.notifyDataSetChanged();
    }
}
