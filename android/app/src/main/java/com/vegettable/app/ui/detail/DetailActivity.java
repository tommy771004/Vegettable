package com.vegettable.app.ui.detail;

import android.content.Intent;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.util.TypedValue;
import android.view.Gravity;
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

    /** dp → px 轉換 */
    private int dp(int dpVal) {
        return (int) TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_DIP, dpVal,
                getResources().getDisplayMetrics());
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

        updateFavoriteIcon();
        btnFavorite.setOnClickListener(v -> {
            if (cropCode != null) {
                prefs.toggleFavorite(cropCode);
                updateFavoriteIcon();
            }
        });

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

    /**
     * Loads detailed information for the current crop and updates the UI accordingly.
     *
     * Shows a progress indicator, requests product detail for `cropName`, and on a successful response
     * displays the received ProductDetail via `displayDetail`. The progress indicator is hidden when
     * the response completes or fails. If the activity is finishing or destroyed, no UI updates occur.
     */
    private void loadProductDetail() {
        progressDetail.setVisibility(View.VISIBLE);

        ApiClient.getInstance().getApi().getProductDetail(cropName)
                .enqueue(new Callback<ApiResponse<ProductDetail>>() {
                    @Override
                    public void onResponse(@NonNull Call<ApiResponse<ProductDetail>> call,
                                           @NonNull Response<ApiResponse<ProductDetail>> response) {
                        if (isFinishing() || isDestroyed()) return;
                        progressDetail.setVisibility(View.GONE);

                        if (response.isSuccessful() && response.body() != null
                                && response.body().isSuccess() && response.body().getData() != null) {
                            displayDetail(response.body().getData());
                        }
                    }

                    @Override
                    public void onFailure(@NonNull Call<ApiResponse<ProductDetail>> call,
                                          @NonNull Throwable t) {
                        if (isFinishing() || isDestroyed()) return;
                        progressDetail.setVisibility(View.GONE);
                    }
                });
    }

    /** 日期標籤格式化：「115.03.02」→「03/02」 */
    private String formatDateLabel(String raw) {
        if (raw == null) return "";
        if (raw.contains(".")) {
            String[] parts = raw.split("\\.");
            if (parts.length >= 3) return parts[1] + "/" + parts[2];
        }
        if (raw.contains("-")) {
            String[] parts = raw.split("-");
            if (parts.length >= 3) return parts[1] + "/" + parts[2];
        }
        return raw;
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
        badgeBg.setCornerRadius(dp(20));
        tvLevelBadge.setBackground(badgeBg);

        // 歷史均價
        tvHistorical.setText(PriceUtils.formatPrice(detail.getHistoricalAvgPrice()) + " 元");

        // 交易量
        if (detail.getDailyPrices() != null && !detail.getDailyPrices().isEmpty()) {
            double vol = detail.getDailyPrices().get(detail.getDailyPrices().size() - 1).getVolume();
            tvVolume.setText(PriceUtils.formatPrice(vol) + " 公斤");
        }

        // 日價格圖表（最近 7 天）
        displayDailyChart(chartDailyContainer, detail.getDailyPrices());

        // 月均價圖表（最近 12 個月）
        List<MonthlyPrice> monthly = detail.getMonthlyPrices();
        if (monthly != null && monthly.size() > 12) {
            monthly = monthly.subList(monthly.size() - 12, monthly.size());
        }
        displayMonthlyChart(chartMonthlyContainer, monthly);
    }

    private void displayDailyChart(LinearLayout container, List<DailyPrice> prices) {
        container.removeAllViews();
        container.setOrientation(LinearLayout.VERTICAL);
        if (prices == null || prices.isEmpty()) return;

        int start = Math.max(0, prices.size() - 7);
        List<DailyPrice> recent = prices.subList(start, prices.size());

        double maxPrice = 0;
        for (DailyPrice dp : recent) {
            maxPrice = Math.max(maxPrice, dp.getAvgPrice());
        }

        for (DailyPrice dp : recent) {
            container.addView(createChartRow(
                    formatDateLabel(dp.getDate()),
                    dp.getAvgPrice(),
                    maxPrice,
                    Color.parseColor("#43A047"),
                    dp(48)
            ));
        }
    }

    private void displayMonthlyChart(LinearLayout container, List<MonthlyPrice> prices) {
        container.removeAllViews();
        container.setOrientation(LinearLayout.VERTICAL);
        if (prices == null || prices.isEmpty()) return;

        double maxPrice = 0;
        for (MonthlyPrice mp : prices) {
            maxPrice = Math.max(maxPrice, mp.getAvgPrice());
        }

        for (MonthlyPrice mp : prices) {
            container.addView(createChartRow(
                    mp.getMonth(),
                    mp.getAvgPrice(),
                    maxPrice,
                    Color.parseColor("#42A5F5"),
                    dp(56)
            ));
        }
    }

    /** 建立圖表單列：[標籤] [軌道+值條] [數值] */
    private LinearLayout createChartRow(String label, double value, double maxValue,
                                        int barColor, int labelWidth) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(0, dp(3), 0, dp(3));

        // 標籤
        TextView tvLabel = new TextView(this);
        tvLabel.setText(label);
        tvLabel.setTextSize(TypedValue.COMPLEX_UNIT_SP, 11);
        tvLabel.setTextColor(Color.parseColor("#8899A6"));
        tvLabel.setMaxLines(1);
        LinearLayout.LayoutParams labelParams = new LinearLayout.LayoutParams(
                labelWidth, LinearLayout.LayoutParams.WRAP_CONTENT);
        tvLabel.setLayoutParams(labelParams);

        // 背景軌道 + 值條
        LinearLayout barWrapper = new LinearLayout(this);
        LinearLayout.LayoutParams wrapperParams = new LinearLayout.LayoutParams(0, dp(18), 1f);
        wrapperParams.setMarginStart(dp(6));
        barWrapper.setLayoutParams(wrapperParams);

        GradientDrawable trackBg = new GradientDrawable();
        trackBg.setColor(Color.parseColor("#14808080"));
        trackBg.setCornerRadius(dp(5));
        barWrapper.setBackground(trackBg);

        View bar = new View(this);
        int barWidth = maxValue > 0 ? (int) (value / maxValue * dp(160)) : 0;
        barWidth = Math.max(dp(4), barWidth);
        LinearLayout.LayoutParams barParams = new LinearLayout.LayoutParams(barWidth, dp(18));
        bar.setLayoutParams(barParams);

        GradientDrawable barBg = new GradientDrawable();
        barBg.setColor(barColor);
        barBg.setCornerRadius(dp(5));
        bar.setBackground(barBg);
        barWrapper.addView(bar);

        // 數值
        TextView tvVal = new TextView(this);
        tvVal.setText(PriceUtils.formatPrice(value));
        tvVal.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        tvVal.setTextColor(Color.parseColor("#0F1419"));
        tvVal.setMaxLines(1);
        tvVal.setGravity(Gravity.END);
        LinearLayout.LayoutParams valParams = new LinearLayout.LayoutParams(
                dp(44), LinearLayout.LayoutParams.WRAP_CONTENT);
        valParams.setMarginStart(dp(6));
        tvVal.setLayoutParams(valParams);

        row.addView(tvLabel);
        row.addView(barWrapper);
        row.addView(tvVal);
        return row;
    }

    /**
     * Loads the price prediction for the current crop and updates the prediction card UI.
     *
     * <p>Requests a remote prediction and, on a successful response with valid data,
     * makes the prediction card visible, populates the prediction text (predicted price,
     * trend arrow, percent change, confidence, and reasoning), and sets the confidence progress.
     * Failures are silently ignored and do not modify the UI.</p>
     */
    private void loadPrediction() {
        if (cropName == null) return;

        ApiClient.getInstance().getApi().getPrediction(cropName)
                .enqueue(new Callback<ApiResponse<PricePrediction>>() {
                    @Override
                    public void onResponse(@NonNull Call<ApiResponse<PricePrediction>> call,
                                           @NonNull Response<ApiResponse<PricePrediction>> response) {
                        if (isFinishing() || isDestroyed()) return;
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
                                          @NonNull Throwable t) { /* 靜默失敗，預測為次要功能 */ }
                });
    }

    /**
     * Loads recipe data for the current crop and, on success, shows the recipes card and populates the recipe list.
     *
     * Performs a network request for recipes associated with `cropName`. If the activity is finishing/destroyed or
     * `cropName` is null, the method returns without action. On a successful API response containing non-empty data,
     * `cardRecipes` is made visible and `displayRecipes` is called with the retrieved list. Failures are handled silently.
     */
    private void loadRecipes() {
        if (cropName == null) return;

        ApiClient.getInstance().getApi().getRecipes(cropName)
                .enqueue(new Callback<ApiResponse<List<Recipe>>>() {
                    @Override
                    public void onResponse(@NonNull Call<ApiResponse<List<Recipe>>> call,
                                           @NonNull Response<ApiResponse<List<Recipe>>> response) {
                        if (isFinishing() || isDestroyed()) return;
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
                                          @NonNull Throwable t) { /* 靜默失敗，食譜為次要功能 */ }
                });
    }

    private void displayRecipes(List<Recipe> recipes) {
        layoutRecipes.removeAllViews();

        // 從 theme 取得顏色，支援 Dark Mode
        TypedValue typedValue = new TypedValue();
        getTheme().resolveAttribute(com.google.android.material.R.attr.colorOnSurface, typedValue, true);
        int primaryTextColor = typedValue.data;

        getTheme().resolveAttribute(com.google.android.material.R.attr.colorOnSurfaceVariant, typedValue, true);
        int secondaryTextColor = typedValue.data;

        for (Recipe r : recipes) {
            LinearLayout item = new LinearLayout(this);
            item.setOrientation(LinearLayout.VERTICAL);
            item.setPadding(0, dp(6), 0, dp(6));

            TextView tvName = new TextView(this);
            tvName.setText(r.getName() + " (" + r.getCookTimeMinutes() + "分)");
            tvName.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
            tvName.setTextColor(primaryTextColor);

            TextView tvDesc = new TextView(this);
            tvDesc.setText(r.getDescription());
            tvDesc.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
            tvDesc.setTextColor(secondaryTextColor);

            item.addView(tvName);
            item.addView(tvDesc);
            layoutRecipes.addView(item);
        }
    }
}
