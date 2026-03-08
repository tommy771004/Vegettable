package com.vegettable.app.ui.compare;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.textfield.TextInputEditText;
import com.vegettable.app.R;
import com.vegettable.app.model.ApiResponse;
import com.vegettable.app.model.MarketPrice;
import com.vegettable.app.network.ApiClient;
import com.vegettable.app.util.PriceUtils;

import java.util.ArrayList;
import java.util.List;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class CompareActivity extends AppCompatActivity {

    private TextInputEditText etCropName;
    private RecyclerView rvCompare;
    private ProgressBar progressBar;
    private LinearLayout layoutError;
    private TextView tvError;
    private CompareAdapter adapter;
    private String lastCropName;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_compare);

        findViewById(R.id.btn_back).setOnClickListener(v -> finish());

        etCropName = findViewById(R.id.et_crop_name);
        rvCompare = findViewById(R.id.rv_compare);
        progressBar = findViewById(R.id.progress_bar);
        layoutError = findViewById(R.id.layout_error);
        tvError = findViewById(R.id.tv_error);

        rvCompare.setLayoutManager(new LinearLayoutManager(this));
        adapter = new CompareAdapter();
        rvCompare.setAdapter(adapter);

        findViewById(R.id.btn_retry).setOnClickListener(v -> {
            if (lastCropName != null && !lastCropName.isEmpty()) {
                comparePrices(lastCropName);
            }
        });

        etCropName.setOnEditorActionListener((v, actionId, event) -> {
            if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                String crop = etCropName.getText().toString().trim();
                if (!crop.isEmpty()) {
                    comparePrices(crop);
                }
                return true;
            }
            return false;
        });
    }

    private void comparePrices(String cropName) {
        lastCropName = cropName;
        progressBar.setVisibility(View.VISIBLE);
        layoutError.setVisibility(View.GONE);

        ApiClient.getInstance().getApi().compareMarketPrices(cropName, null)
                .enqueue(new Callback<ApiResponse<List<MarketPrice>>>() {
                    @Override
                    public void onResponse(@NonNull Call<ApiResponse<List<MarketPrice>>> call,
                                           @NonNull Response<ApiResponse<List<MarketPrice>>> response) {
                        progressBar.setVisibility(View.GONE);
                        if (response.isSuccessful() && response.body() != null
                                && response.body().isSuccess() && response.body().getData() != null) {
                            adapter.setItems(response.body().getData());
                            rvCompare.setVisibility(View.VISIBLE);
                        } else {
                            showError("無法取得比價資料");
                        }
                    }

                    @Override
                    public void onFailure(@NonNull Call<ApiResponse<List<MarketPrice>>> call,
                                          @NonNull Throwable t) {
                        progressBar.setVisibility(View.GONE);
                        showError("網路錯誤: " + t.getMessage());
                    }
                });
    }

    private void showError(String message) {
        tvError.setText(message);
        layoutError.setVisibility(View.VISIBLE);
    }

    // ─── Adapter ────────────────────────────────────────────
    static class CompareAdapter extends RecyclerView.Adapter<CompareAdapter.VH> {
        private List<MarketPrice> items = new ArrayList<>();

        void setItems(List<MarketPrice> items) {
            this.items = items;
            notifyDataSetChanged();
        }

        @NonNull @Override
        public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            View v = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_compare, parent, false);
            return new VH(v);
        }

        @Override
        public void onBindViewHolder(@NonNull VH h, int pos) {
            MarketPrice mp = items.get(pos);
            h.tvMarketName.setText(mp.getMarketName());
            h.tvDate.setText(mp.getTransDate());
            h.tvAvgPrice.setText(PriceUtils.formatPrice(mp.getAvgPrice()) + " 元/公斤");
            h.tvPriceRange.setText(PriceUtils.formatPrice(mp.getLowerPrice())
                    + " ~ " + PriceUtils.formatPrice(mp.getUpperPrice()));
        }

        @Override public int getItemCount() { return items.size(); }

        static class VH extends RecyclerView.ViewHolder {
            TextView tvMarketName, tvDate, tvAvgPrice, tvPriceRange;
            VH(View v) {
                super(v);
                tvMarketName = v.findViewById(R.id.tv_market_name);
                tvDate = v.findViewById(R.id.tv_date);
                tvAvgPrice = v.findViewById(R.id.tv_avg_price);
                tvPriceRange = v.findViewById(R.id.tv_price_range);
            }
        }
    }
}
