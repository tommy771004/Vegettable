package com.vegettable.app.ui.map;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.button.MaterialButton;
import com.google.android.material.chip.Chip;
import com.google.android.material.chip.ChipGroup;
import com.vegettable.app.R;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class MapActivity extends AppCompatActivity {

    private MarketAdapter adapter;
    private String selectedRegion = null;

    // 批發市場資料
    private static final List<MarketItem> ALL_MARKETS = Arrays.asList(
        new MarketItem("台北一", "台北市萬華區萬大路533號", "北部", 25.0258, 121.5010),
        new MarketItem("台北二", "台北市中山區民族東路336號", "北部", 25.0690, 121.5375),
        new MarketItem("三重", "新北市三重區大同北路107號", "北部", 25.0620, 121.4872),
        new MarketItem("桃園", "桃園市桃園區中山路590號", "北部", 24.9917, 121.3125),
        new MarketItem("台中", "台中市西屯區中清路350號", "中部", 24.1795, 120.6547),
        new MarketItem("溪湖", "彰化縣溪湖鎮彰水路四段510號", "中部", 23.9617, 120.4793),
        new MarketItem("西螺", "雲林縣西螺鎮九隆里延平路248號", "中部", 23.7983, 120.4602),
        new MarketItem("嘉義", "嘉義市西區博愛路二段459號", "南部", 23.4817, 120.4343),
        new MarketItem("台南", "台南市北區忠北街7號", "南部", 23.0125, 120.2153),
        new MarketItem("鳳山", "高雄市鳳山區建國路三段39號", "南部", 22.6273, 120.3419),
        new MarketItem("屏東", "屏東縣屏東市工業路9號", "南部", 22.6656, 120.4950),
        new MarketItem("宜蘭", "宜蘭縣宜蘭市環市東路二段1號", "東部", 24.7469, 121.7515),
        new MarketItem("花蓮", "花蓮縣花蓮市中華路100號", "東部", 23.9872, 121.6044)
    );

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_map);

        findViewById(R.id.btn_back).setOnClickListener(v -> finish());

        RecyclerView rvMarkets = findViewById(R.id.rv_markets);
        rvMarkets.setLayoutManager(new LinearLayoutManager(this));
        adapter = new MarketAdapter();
        rvMarkets.setAdapter(adapter);
        adapter.setItems(ALL_MARKETS);

        setupRegionChips();
    }

    private void setupRegionChips() {
        ChipGroup group = findViewById(R.id.chip_group_region);
        String[] regions = {"全部", "北部", "中部", "南部", "東部"};
        for (String r : regions) {
            Chip chip = new Chip(this);
            chip.setText(r);
            chip.setCheckable(true);
            if ("全部".equals(r)) chip.setChecked(true);
            chip.setOnCheckedChangeListener((btn, checked) -> {
                if (checked) {
                    selectedRegion = "全部".equals(btn.getText().toString()) ? null : btn.getText().toString();
                    filterMarkets();
                }
            });
            group.addView(chip);
        }
    }

    private void filterMarkets() {
        if (selectedRegion == null) {
            adapter.setItems(ALL_MARKETS);
        } else {
            List<MarketItem> filtered = new ArrayList<>();
            for (MarketItem m : ALL_MARKETS) {
                if (selectedRegion.equals(m.region)) {
                    filtered.add(m);
                }
            }
            adapter.setItems(filtered);
        }
    }

    // ─── Data ────────────────────────────────────────────────
    static class MarketItem {
        final String name, address, region;
        final double lat, lng;
        MarketItem(String name, String address, String region, double lat, double lng) {
            this.name = name; this.address = address; this.region = region;
            this.lat = lat; this.lng = lng;
        }
    }

    // ─── Adapter ────────────────────────────────────────────
    class MarketAdapter extends RecyclerView.Adapter<MarketAdapter.VH> {
        private List<MarketItem> items = new ArrayList<>();

        void setItems(List<MarketItem> items) {
            this.items = items;
            notifyDataSetChanged();
        }

        @NonNull @Override
        public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            View v = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_market, parent, false);
            return new VH(v);
        }

        @Override
        public void onBindViewHolder(@NonNull VH h, int pos) {
            MarketItem m = items.get(pos);
            h.tvName.setText(m.name + "果菜批發市場");
            h.tvAddress.setText(m.address);
            h.tvRegion.setText(m.region);
            h.btnNavigate.setOnClickListener(v -> {
                Uri uri = Uri.parse("geo:" + m.lat + "," + m.lng + "?q=" + Uri.encode(m.address));
                Intent intent = new Intent(Intent.ACTION_VIEW, uri);
                startActivity(intent);
            });
        }

        @Override public int getItemCount() { return items.size(); }

        class VH extends RecyclerView.ViewHolder {
            TextView tvName, tvAddress, tvRegion;
            MaterialButton btnNavigate;
            VH(View v) {
                super(v);
                tvName = v.findViewById(R.id.tv_market_name);
                tvAddress = v.findViewById(R.id.tv_address);
                tvRegion = v.findViewById(R.id.tv_region);
                btnNavigate = v.findViewById(R.id.btn_navigate);
            }
        }
    }
}
