package com.vegettable.app.ui.seasonal;

import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.chip.Chip;
import com.google.android.material.chip.ChipGroup;
import com.vegettable.app.R;
import com.vegettable.app.model.ApiResponse;
import com.vegettable.app.model.SeasonalInfo;
import com.vegettable.app.network.ApiClient;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class SeasonalActivity extends AppCompatActivity {

    private RecyclerView rvSeasonal;
    private SeasonalAdapter adapter;
    private String selectedCategory = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_seasonal);

        findViewById(R.id.btn_back).setOnClickListener(v -> finish());

        rvSeasonal = findViewById(R.id.rv_seasonal);
        rvSeasonal.setLayoutManager(new LinearLayoutManager(this));
        adapter = new SeasonalAdapter();
        rvSeasonal.setAdapter(adapter);

        setupCategoryChips();
        loadSeasonal();
    }

    private void setupCategoryChips() {
        ChipGroup group = findViewById(R.id.chip_group_category);
        String[][] cats = {{"", "全部"}, {"vegetable", "蔬菜"}, {"fruit", "水果"}};
        for (String[] c : cats) {
            Chip chip = new Chip(this);
            chip.setText(c[1]);
            chip.setCheckable(true);
            chip.setTag(c[0]);
            if (c[0].isEmpty()) chip.setChecked(true);
            chip.setOnCheckedChangeListener((btn, checked) -> {
                if (checked) {
                    String tag = (String) btn.getTag();
                    selectedCategory = tag.isEmpty() ? null : tag;
                    loadSeasonal();
                }
            });
            group.addView(chip);
        }
    }

    private void loadSeasonal() {
        ApiClient.getInstance().getApi().getSeasonalInfo(selectedCategory)
                .enqueue(new Callback<ApiResponse<List<SeasonalInfo>>>() {
                    @Override
                    public void onResponse(@NonNull Call<ApiResponse<List<SeasonalInfo>>> call,
                                           @NonNull Response<ApiResponse<List<SeasonalInfo>>> response) {
                        if (response.isSuccessful() && response.body() != null
                                && response.body().isSuccess() && response.body().getData() != null) {
                            adapter.setItems(response.body().getData());
                        }
                    }

                    @Override
                    public void onFailure(@NonNull Call<ApiResponse<List<SeasonalInfo>>> call,
                                          @NonNull Throwable t) { }
                });
    }

    // ─── Adapter ────────────────────────────────────────────
    static class SeasonalAdapter extends RecyclerView.Adapter<SeasonalAdapter.VH> {
        private List<SeasonalInfo> items = new ArrayList<>();

        void setItems(List<SeasonalInfo> items) {
            this.items = items;
            notifyDataSetChanged();
        }

        @NonNull
        @Override
        public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            View v = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_seasonal, parent, false);
            return new VH(v);
        }

        @Override
        public void onBindViewHolder(@NonNull VH h, int pos) {
            SeasonalInfo info = items.get(pos);
            h.tvName.setText(info.getCropName());
            h.tvNote.setText(info.getSeasonNote());

            // 當季 badge
            if (info.isInSeason()) {
                h.tvBadge.setText("當季");
                h.tvBadge.setTextColor(Color.parseColor("#2E7D32"));
                GradientDrawable bg = new GradientDrawable();
                bg.setColor(Color.parseColor("#1A4CAF50"));
                bg.setCornerRadius(20f);
                h.tvBadge.setBackground(bg);
            } else {
                h.tvBadge.setText("非當季");
                h.tvBadge.setTextColor(Color.parseColor("#757575"));
                GradientDrawable bg = new GradientDrawable();
                bg.setColor(Color.parseColor("#10808080"));
                bg.setCornerRadius(20f);
                h.tvBadge.setBackground(bg);
            }

            // 12 月份
            h.layoutMonths.removeAllViews();
            int currentMonth = Calendar.getInstance().get(Calendar.MONTH) + 1;
            List<Integer> peaks = info.getPeakMonths() != null ? info.getPeakMonths() : new ArrayList<>();

            for (int m = 1; m <= 12; m++) {
                TextView tv = new TextView(h.itemView.getContext());
                tv.setText(String.valueOf(m));
                tv.setTextSize(10);
                tv.setGravity(android.view.Gravity.CENTER);

                LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, 28, 1f);
                params.setMargins(1, 0, 1, 0);
                tv.setLayoutParams(params);

                GradientDrawable cellBg = new GradientDrawable();
                cellBg.setCornerRadius(4f);
                if (peaks.contains(m)) {
                    cellBg.setColor(Color.parseColor("#4CAF50"));
                    tv.setTextColor(Color.WHITE);
                } else if (m == currentMonth) {
                    cellBg.setColor(Color.parseColor("#E8F5E9"));
                    tv.setTextColor(Color.parseColor("#2E7D32"));
                } else {
                    cellBg.setColor(Color.parseColor("#F5F5F5"));
                    tv.setTextColor(Color.parseColor("#9E9E9E"));
                }
                tv.setBackground(cellBg);
                h.layoutMonths.addView(tv);
            }
        }

        @Override
        public int getItemCount() { return items.size(); }

        static class VH extends RecyclerView.ViewHolder {
            TextView tvName, tvBadge, tvNote;
            LinearLayout layoutMonths;
            VH(View v) {
                super(v);
                tvName = v.findViewById(R.id.tv_crop_name);
                tvBadge = v.findViewById(R.id.tv_season_badge);
                tvNote = v.findViewById(R.id.tv_note);
                layoutMonths = v.findViewById(R.id.layout_months);
            }
        }
    }
}
