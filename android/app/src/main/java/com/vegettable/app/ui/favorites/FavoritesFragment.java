package com.vegettable.app.ui.favorites;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.vegettable.app.R;
import com.vegettable.app.model.ApiResponse;
import com.vegettable.app.model.ProductSummary;
import com.vegettable.app.network.ApiClient;
import com.vegettable.app.ui.adapter.ProductAdapter;
import com.vegettable.app.ui.detail.DetailActivity;
import com.vegettable.app.util.PrefsManager;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class FavoritesFragment extends Fragment implements ProductAdapter.OnItemClickListener {

    private RecyclerView rvFavorites;
    private TextView tvEmpty, tvFavCount;
    private ProductAdapter adapter;
    private PrefsManager prefs;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_favorites, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        prefs = new PrefsManager(requireContext());

        rvFavorites = view.findViewById(R.id.rv_favorites);
        tvEmpty = view.findViewById(R.id.tv_empty);
        tvFavCount = view.findViewById(R.id.tv_fav_count);

        rvFavorites.setLayoutManager(new LinearLayoutManager(requireContext()));
        adapter = new ProductAdapter(this, prefs.getFavorites());
        adapter.setPriceUnit(prefs.getPriceUnit());
        rvFavorites.setAdapter(adapter);

        loadFavorites();
    }

    @Override
    public void onResume() {
        super.onResume();
        loadFavorites();
    }

    private void loadFavorites() {
        Set<String> favCodes = prefs.getFavorites();

        if (favCodes.isEmpty()) {
            tvEmpty.setVisibility(View.VISIBLE);
            rvFavorites.setVisibility(View.GONE);
            tvFavCount.setText("0 項收藏");
            return;
        }

        tvFavCount.setText(favCodes.size() + " 項收藏");

        // 從快取中過濾收藏項目
        String cached = prefs.getCachedProducts();
        if (cached != null) {
            try {
                List<ProductSummary> all = new Gson().fromJson(cached,
                        new TypeToken<List<ProductSummary>>(){}.getType());
                List<ProductSummary> favProducts = new ArrayList<>();
                for (ProductSummary p : all) {
                    if (favCodes.contains(p.getCropCode())) {
                        favProducts.add(p);
                    }
                }
                if (!favProducts.isEmpty()) {
                    adapter.setItems(favProducts);
                    rvFavorites.setVisibility(View.VISIBLE);
                    tvEmpty.setVisibility(View.GONE);
                    return;
                }
            } catch (Exception ignored) {}
        }

        // 若快取為空，從 API 載入全部產品再過濾
        ApiClient.getInstance().getApi().getProducts(null)
                .enqueue(new Callback<ApiResponse<List<ProductSummary>>>() {
                    @Override
                    public void onResponse(@NonNull Call<ApiResponse<List<ProductSummary>>> call,
                                           @NonNull Response<ApiResponse<List<ProductSummary>>> response) {
                        if (!isAdded()) return;
                        if (response.isSuccessful() && response.body() != null
                                && response.body().isSuccess() && response.body().getData() != null) {
                            List<ProductSummary> favProducts = new ArrayList<>();
                            for (ProductSummary p : response.body().getData()) {
                                if (favCodes.contains(p.getCropCode())) {
                                    favProducts.add(p);
                                }
                            }
                            adapter.setItems(favProducts);
                            rvFavorites.setVisibility(favProducts.isEmpty() ? View.GONE : View.VISIBLE);
                            tvEmpty.setVisibility(favProducts.isEmpty() ? View.VISIBLE : View.GONE);
                        }
                    }

                    @Override
                    public void onFailure(@NonNull Call<ApiResponse<List<ProductSummary>>> call,
                                          @NonNull Throwable t) {
                        if (!isAdded()) return;
                        tvEmpty.setVisibility(View.VISIBLE);
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
        loadFavorites();
    }
}
