package com.vegettable.app.ui.detail;

import android.content.Intent;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.card.MaterialCardView;
import com.vegettable.app.R;
import com.vegettable.app.model.*;
import com.vegettable.app.network.ApiClient;
import com.vegettable.app.util.PrefsManager;
import com.vegettable.app.util.PriceUtils;

import java.util.List;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class DetailActivity extends AppCompatActivity {

    private String cropName;
    private String cropCode;
    private PrefsManager prefs;

    private TextView tvTitle, tvAliases, tvPrice, tvTrendArrow, tvLevelBadge;
    private TextView tvPriceUnit, tvHistorical, tvVolume;
    private TextView tvPrediction;
    private ImageButton btnBack, btnFavorite, btnShare;
    private ProgressBar progressDetail, progressConfidence;
    private MaterialCardView cardPrediction, cardRecipes;
    private LinearLayout layoutRecipes, chartDailyContainer, chartMonthlyContainer;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_detail);

        prefs = new PrefsManager(this);
        cropName = getIntent().getStringExtra("cropName");
        cropCode = getIntent().getStringExtra("cropCode");

        bindViews();
        setupActions();
        loadProductDetail();
        loadPrediction();
        loadRecipes();
    }

    private void bindViews() {
        tvTitle = findViewById(R.id.tv_title);
        tvAliases = findViewById(R.id.tv_aliases);
        tvPrice = findViewById(R.id.tv_price);
        tvTrendArrow = findViewById(R.id.tv_trend_arrow);
        tvLevelBadge = findViewById(R.id.tv_level_badge);
        tvPriceUnit = findViewById(R.id.tv_price_unit);
        tvHistorical = findViewById(R.id.tv_historical);
        tvVolume = findViewById(R.id.tv_volume);
        tvPrediction = findViewById(R.id.tv_prediction);
        btnBack = findViewById(R.id.btn_back);
        btnFavorite = findViewById(R.id.btn_favorite);
        btnShare = findViewById(R.id.btn_share);
        progressDetail = findViewById(R.id.progress_detail);
        progressConfidence = findViewById(R.id.progress_confidence);
        cardPrediction = findViewById(R.id.card_prediction);
        cardRecipes = findViewById(R.id.card_recipes);
        layoutRecipes = findViewById(R.id.layout_recipes);
        chartDailyContainer = findViewById(R.id.chart_daily_container);
        chartMonthlyContainer = findViewById(R.id.chart_monthly_container);

        tvTitle.setText(cropName != null ? cropName : "");
    }

    private void setupActions() {
        btnBack.setOnClickListener(v -> finish());

        // 收藏
        updateFavoriteIcon();
        btnFavorite.setOnClickListener(v -> {
            if (cropCode != null) {
                prefs.toggleFavorite(cropCode);
                updateFavoriteIcon();
            }
        });

        // 分享
        btnShare.setOnClickListener(v -> {
            String shareText = cropName + " — 菜價查詢 App";
            Intent intent = new Intent(Intent.ACTION_SEND);
            intent.setType("text/plain");
            intent.putExtra(Intent.EXTRA_TEXT, shareText);
            startActivity(Intent.createChooser(intent, "分享"));
        });
    }

    private void updateFavoriteIcon() {
        boolean isFav = cropCode != null && prefs.isFavorite(cropCode);
        btnFavorite.setImageResource(isFav
                ? android.R.drawable.btn_star_big_on
                : android.R.drawable.btn_star_big_off);
    }

    private void loadProductDetail() {
        progressDetail.setVisibility(View.VISIBLE);

        ApiClient.getInstance().getApi().getProductDetail(cropName)
                .enqueue(new Callback<ApiResponse<ProductDetail>>() {
                    @Override
                    public void onResponse(@NonNull Call<ApiResponse<ProductDetail>> call,
                                           @NonNull Response<ApiResponse<ProductDetail>> response) {
                        progressDetail.setVisibility(View.GONE);

                        if (response.isSuccessful() && response.body() != null
                                && response.body().isSuccess() && response.body().getData() != null) {
                            displayDetail(response.body().getData());
                        }
                    }

                    @Override
                    public void onFailure(@NonNull Call<ApiResponse<ProductDetail>> call,
                                          @NonNull Throwable t) {
                        progressDetail.setVisibility(View.GONE);
                    }
                });
    }

    private void displayDetail(ProductDetail detail) {
        // 別名
        if (detail.getAliases() != null && !detail.getAliases().isEmpty()) {
            tvAliases.setText("又稱：" + String.join("、", detail.getAliases()));
            tvAliases.setVisibility(View.VISIBLE);
        }

        // 主要價格
        double price = detail.getAvgPrice();
        String unit = prefs.getPriceUnit();
        if ("catty".equals(unit)) {
            price = PriceUtils.convertToCatty(price);
        }
        tvPrice.setText(PriceUtils.formatPrice(price));
        tvPrice.setTextColor(PriceUtils.getPriceLevelColor(detail.getPriceLevel()));

        tvPriceUnit.setText("catty".equals(unit) ? "元/台斤（批發）" : "元/公斤（批發）");

        // 趨勢
        tvTrendArrow.setText(PriceUtils.getTrendArrow(detail.getTrend()));
        tvTrendArrow.setTextColor(PriceUtils.getTrendColor(detail.getTrend()));

        // 等級 Badge
        tvLevelBadge.setText(PriceUtils.getPriceLevelLabel(detail.getPriceLevel()));
        tvLevelBadge.setTextColor(PriceUtils.getPriceLevelColor(detail.getPriceLevel()));
        GradientDrawable badgeBg = new GradientDrawable();
        badgeBg.setColor(PriceUtils.getPriceLevelBgColor(detail.getPriceLevel()));
        badgeBg.setCornerRadius(40f);
        tvLevelBadge.setBackground(badgeBg);

        // 歷史均價
        tvHistorical.setText(PriceUtils.formatPrice(detail.getHistoricalAvgPrice()) + " 元");

        // 交易量 — 從日價格列表取最新的 volume
        if (detail.getDailyPrices() != null && !detail.getDailyPrices().isEmpty()) {
            double vol = detail.getDailyPrices().get(detail.getDailyPrices().size() - 1).getVolume();
            tvVolume.setText(PriceUtils.formatPrice(vol) + " 公斤");
        }

        // 簡易圖表 — 使用 TextView 顯示數值（完整圖表需 MPAndroidChart）
        displaySimpleChart(chartDailyContainer, detail.getDailyPrices());
        displaySimpleMonthlyChart(chartMonthlyContainer, detail.getMonthlyPrices());
    }

    private void displaySimpleChart(LinearLayout container, List<DailyPrice> prices) {
        container.removeAllViews();
        if (prices == null || prices.isEmpty()) return;

        double maxPrice = 0;
        for (DailyPrice dp : prices) {
            maxPrice = Math.max(maxPrice, dp.getAvgPrice());
        }

        for (DailyPrice dp : prices) {
            LinearLayout row = new LinearLayout(this);
            row.setOrientation(LinearLayout.HORIZONTAL);
            row.setPadding(0, 4, 0, 4);

            TextView tvDate = new TextView(this);
            tvDate.setText(dp.getDate());
            tvDate.setTextSize(11);
            tvDate.setTextColor(Color.parseColor("#79747E"));
            tvDate.setWidth(120);

            // 簡易 bar
            View bar = new View(this);
            int barWidth = maxPrice > 0 ? (int) (dp.getAvgPrice() / maxPrice * 400) : 0;
            LinearLayout.LayoutParams barParams = new LinearLayout.LayoutParams(barWidth, 16);
            barParams.setMarginStart(8);
            bar.setLayoutParams(barParams);
            GradientDrawable barBg = new GradientDrawable();
            barBg.setColor(Color.parseColor("#4CAF50"));
            barBg.setCornerRadius(8f);
            bar.setBackground(barBg);

            TextView tvVal = new TextView(this);
            tvVal.setText(" " + PriceUtils.formatPrice(dp.getAvgPrice()));
            tvVal.setTextSize(11);
            tvVal.setTextColor(Color.parseColor("#1B1B1F"));

            row.addView(tvDate);
            row.addView(bar);
            row.addView(tvVal);
            container.addView(row);
        }
    }

    private void displaySimpleMonthlyChart(LinearLayout container, List<MonthlyPrice> prices) {
        container.removeAllViews();
        if (prices == null || prices.isEmpty()) return;

        double maxPrice = 0;
        for (MonthlyPrice mp : prices) {
            maxPrice = Math.max(maxPrice, mp.getAvgPrice());
        }

        for (MonthlyPrice mp : prices) {
            LinearLayout row = new LinearLayout(this);
            row.setOrientation(LinearLayout.HORIZONTAL);
            row.setPadding(0, 4, 0, 4);

            TextView tvMonth = new TextView(this);
            tvMonth.setText(mp.getMonth());
            tvMonth.setTextSize(11);
            tvMonth.setTextColor(Color.parseColor("#79747E"));
            tvMonth.setWidth(120);

            View bar = new View(this);
            int barWidth = maxPrice > 0 ? (int) (mp.getAvgPrice() / maxPrice * 400) : 0;
            LinearLayout.LayoutParams barParams = new LinearLayout.LayoutParams(barWidth, 16);
            barParams.setMarginStart(8);
            bar.setLayoutParams(barParams);
            GradientDrawable barBg = new GradientDrawable();
            barBg.setColor(Color.parseColor("#2196F3"));
            barBg.setCornerRadius(8f);
            bar.setBackground(barBg);

            TextView tvVal = new TextView(this);
            tvVal.setText(" " + PriceUtils.formatPrice(mp.getAvgPrice()));
            tvVal.setTextSize(11);

            row.addView(tvMonth);
            row.addView(bar);
            row.addView(tvVal);
            container.addView(row);
        }
    }

    private void loadPrediction() {
        if (cropName == null) return;

        ApiClient.getInstance().getApi().getPrediction(cropName)
                .enqueue(new Callback<ApiResponse<PricePrediction>>() {
                    @Override
                    public void onResponse(@NonNull Call<ApiResponse<PricePrediction>> call,
                                           @NonNull Response<ApiResponse<PricePrediction>> response) {
                        if (response.isSuccessful() && response.body() != null
                                && response.body().isSuccess() && response.body().getData() != null) {
                            PricePrediction pred = response.body().getData();
                            cardPrediction.setVisibility(View.VISIBLE);

                            String arrow = PriceUtils.getTrendArrow(pred.getDirection());
                            String text = String.format("預測價格: %s 元 %s (%.1f%%)\n信心度: %.0f%%\n%s",
                                    PriceUtils.formatPrice(pred.getPredictedPrice()),
                                    arrow, pred.getChangePercent(),
                                    pred.getConfidence(), pred.getReasoning());
                            tvPrediction.setText(text);
                            progressConfidence.setProgress((int) pred.getConfidence());
                        }
                    }

                    @Override
                    public void onFailure(@NonNull Call<ApiResponse<PricePrediction>> call,
                                          @NonNull Throwable t) { }
                });
    }

    private void loadRecipes() {
        if (cropName == null) return;

        ApiClient.getInstance().getApi().getRecipes(cropName)
                .enqueue(new Callback<ApiResponse<List<Recipe>>>() {
                    @Override
                    public void onResponse(@NonNull Call<ApiResponse<List<Recipe>>> call,
                                           @NonNull Response<ApiResponse<List<Recipe>>> response) {
                        if (response.isSuccessful() && response.body() != null
                                && response.body().isSuccess() && response.body().getData() != null) {
                            List<Recipe> recipes = response.body().getData();
                            if (!recipes.isEmpty()) {
                                cardRecipes.setVisibility(View.VISIBLE);
                                displayRecipes(recipes);
                            }
                        }
                    }

                    @Override
                    public void onFailure(@NonNull Call<ApiResponse<List<Recipe>>> call,
                                          @NonNull Throwable t) { }
                });
    }

    private void displayRecipes(List<Recipe> recipes) {
        layoutRecipes.removeAllViews();
        for (Recipe r : recipes) {
            LinearLayout item = new LinearLayout(this);
            item.setOrientation(LinearLayout.VERTICAL);
            item.setPadding(0, 8, 0, 8);

            TextView tvName = new TextView(this);
            tvName.setText(r.getName() + " (" + r.getCookTimeMinutes() + "分)");
            tvName.setTextSize(14);
            tvName.setTextColor(Color.parseColor("#1B1B1F"));

            TextView tvDesc = new TextView(this);
            tvDesc.setText(r.getDescription());
            tvDesc.setTextSize(12);
            tvDesc.setTextColor(Color.parseColor("#49454F"));

            item.addView(tvName);
            item.addView(tvDesc);
            layoutRecipes.addView(item);
        }
    }
}
