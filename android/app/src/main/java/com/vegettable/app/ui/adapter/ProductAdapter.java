package com.vegettable.app.ui.adapter;

import android.graphics.drawable.GradientDrawable;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.DiffUtil;
import androidx.recyclerview.widget.RecyclerView;

import com.vegettable.app.R;
import com.vegettable.app.model.ProductSummary;
import com.vegettable.app.util.PriceUtils;

import java.util.ArrayList;
import java.util.List;

public class ProductAdapter extends RecyclerView.Adapter<ProductAdapter.ViewHolder> {

    public interface OnItemClickListener {
        void onItemClick(ProductSummary product);
        void onFavoriteClick(ProductSummary product);
    }

    private List<ProductSummary> items = new ArrayList<>();
    private final OnItemClickListener listener;
    private final java.util.Set<String> favorites;
    private String priceUnit = "kg";
    private boolean showRetail = false;

    public ProductAdapter(OnItemClickListener listener, java.util.Set<String> favorites) {
        this.listener = listener;
        this.favorites = favorites;
    }

    public void setItems(List<ProductSummary> newItems) {
        DiffUtil.DiffResult result = DiffUtil.calculateDiff(new DiffUtil.Callback() {
            @Override
            public int getOldListSize() { return items.size(); }
            @Override
            public int getNewListSize() { return newItems.size(); }
            @Override
            public boolean areItemsTheSame(int oldPos, int newPos) {
                return items.get(oldPos).getCropCode().equals(newItems.get(newPos).getCropCode());
            }
            @Override
            public boolean areContentsTheSame(int oldPos, int newPos) {
                ProductSummary o = items.get(oldPos);
                ProductSummary n = newItems.get(newPos);
                return o.getCropCode().equals(n.getCropCode())
                        && o.getAvgPrice() == n.getAvgPrice()
                        && java.util.Objects.equals(o.getPriceLevel(), n.getPriceLevel())
                        && java.util.Objects.equals(o.getTrend(), n.getTrend());
            }
        });
        this.items = newItems;
        result.dispatchUpdatesTo(this);
    }

    public void addItems(List<ProductSummary> newItems) {
        int start = items.size();
        items.addAll(newItems);
        notifyItemRangeInserted(start, newItems.size());
    }

    public void setPriceUnit(String unit) {
        if (!this.priceUnit.equals(unit)) {
            this.priceUnit = unit;
            notifyItemRangeChanged(0, items.size());
        }
    }

    public void setShowRetail(boolean showRetail) {
        if (this.showRetail != showRetail) {
            this.showRetail = showRetail;
            notifyItemRangeChanged(0, items.size());
        }
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_product, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        ProductSummary product = items.get(position);
        holder.bind(product);
    }

    @Override
    public int getItemCount() {
        return items.size();
    }

    class ViewHolder extends RecyclerView.ViewHolder {
        private final TextView tvName, tvAliases, tvPrice, tvTrend, tvUnit, tvLevel;
        private final ImageButton btnFav;

        ViewHolder(View itemView) {
            super(itemView);
            tvName = itemView.findViewById(R.id.tv_crop_name);
            tvAliases = itemView.findViewById(R.id.tv_aliases);
            tvPrice = itemView.findViewById(R.id.tv_price);
            tvTrend = itemView.findViewById(R.id.tv_trend);
            tvUnit = itemView.findViewById(R.id.tv_unit);
            tvLevel = itemView.findViewById(R.id.tv_price_level);
            btnFav = itemView.findViewById(R.id.btn_favorite);
        }

        void bind(ProductSummary p) {
            tvName.setText(p.getCropName());

            // 別名
            if (p.getAliases() != null && !p.getAliases().isEmpty()) {
                tvAliases.setText(String.join("、", p.getAliases()));
                tvAliases.setVisibility(View.VISIBLE);
            } else {
                tvAliases.setVisibility(View.GONE);
            }

            // 價格
            double displayPrice = p.getAvgPrice();
            if ("catty".equals(priceUnit)) {
                displayPrice = PriceUtils.convertToCatty(displayPrice);
            }
            if (showRetail) {
                displayPrice = PriceUtils.estimateRetailPrice(displayPrice);
            }
            tvPrice.setText(PriceUtils.formatPrice(displayPrice));
            tvPrice.setTextColor(PriceUtils.getPriceLevelColor(p.getPriceLevel()));

            // 趨勢
            tvTrend.setText(PriceUtils.getTrendArrow(p.getTrend()));
            tvTrend.setTextColor(PriceUtils.getTrendColor(p.getTrend()));

            // 單位
            tvUnit.setText("catty".equals(priceUnit) ? "元/台斤" : "元/公斤");

            // 價格等級
            String levelLabel = PriceUtils.getPriceLevelLabel(p.getPriceLevel());
            tvLevel.setText(levelLabel);
            tvLevel.setTextColor(PriceUtils.getPriceLevelColor(p.getPriceLevel()));
            GradientDrawable bg = new GradientDrawable();
            bg.setColor(PriceUtils.getPriceLevelBgColor(p.getPriceLevel()));
            bg.setCornerRadius(20f);
            tvLevel.setBackground(bg);

            // 收藏
            boolean isFav = favorites.contains(p.getCropCode());
            btnFav.setImageResource(isFav
                    ? android.R.drawable.btn_star_big_on
                    : android.R.drawable.btn_star_big_off);
            btnFav.setContentDescription(isFav ? "取消收藏" : "加入收藏");
            btnFav.setOnClickListener(v -> listener.onFavoriteClick(p));

            // TalkBack 無障礙
            itemView.setContentDescription(
                    p.getCropName() + "，價格 " + PriceUtils.formatPrice(displayPrice)
                    + " 元，" + levelLabel);

            // 點擊
            itemView.setOnClickListener(v -> listener.onItemClick(p));
        }
    }
}
