package com.vegettable.app.ui.adapter

import android.graphics.drawable.GradientDrawable
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.TextView
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.RecyclerView
import com.vegettable.app.R
import com.vegettable.app.model.ProductSummary
import com.vegettable.app.util.PriceUtils

class ProductAdapter(
    private val listener: OnItemClickListener,
    private var favorites: Set<String> = emptySet()
) : RecyclerView.Adapter<ProductAdapter.ViewHolder?>() {
    interface OnItemClickListener {
        fun onItemClick(product: ProductSummary?)
        fun onFavoriteClick(product: ProductSummary?)
    }

    private var items: MutableList<ProductSummary> = ArrayList<ProductSummary>()
    private var priceUnit: String? = "kg"
    private var showRetail = false

    fun setItems(newItems: MutableList<ProductSummary>) {
        val diff = DiffUtil.calculateDiff(object : DiffUtil.Callback() {
            override fun getOldListSize() = items.size
            override fun getNewListSize() = newItems.size
            override fun areItemsTheSame(oldPos: Int, newPos: Int) =
                items[oldPos].cropCode == newItems[newPos].cropCode
            override fun areContentsTheSame(oldPos: Int, newPos: Int) =
                items[oldPos] == newItems[newPos]
        })
        items = newItems
        diff.dispatchUpdatesTo(this)
    }

    fun setFavorites(favorites: Set<String>) {
        this.favorites = favorites
        notifyDataSetChanged()
    }

    fun setPriceUnit(unit: String?) {
        this.priceUnit = unit
        notifyDataSetChanged()
    }

    fun setShowRetail(showRetail: Boolean) {
        this.showRetail = showRetail
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.getContext())
            .inflate(R.layout.item_product, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val product = items.get(position)
        holder.bind(product)
    }

    override fun getItemCount(): Int {
        return items.size
    }

    inner class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tvName: TextView
        private val tvAliases: TextView
        private val tvPrice: TextView
        private val tvTrend: TextView
        private val tvUnit: TextView
        private val tvLevel: TextView
        private val btnFav: ImageButton

        init {
            tvName = itemView.findViewById<TextView>(R.id.tv_crop_name)
            tvAliases = itemView.findViewById<TextView>(R.id.tv_aliases)
            tvPrice = itemView.findViewById<TextView>(R.id.tv_price)
            tvTrend = itemView.findViewById<TextView>(R.id.tv_trend)
            tvUnit = itemView.findViewById<TextView>(R.id.tv_unit)
            tvLevel = itemView.findViewById<TextView>(R.id.tv_price_level)
            btnFav = itemView.findViewById<ImageButton>(R.id.btn_favorite)
        }

        fun bind(p: ProductSummary) {
            tvName.setText(p.cropName)

            // 別名
            if (p.aliases != null && !p.aliases.isEmpty()) {
                tvAliases.setText(p.aliases.filterNotNull().joinToString("、"))
                tvAliases.setVisibility(View.VISIBLE)
            } else {
                tvAliases.setVisibility(View.GONE)
            }

            // 價格
            var displayPrice = p.avgPrice
            if ("catty" == priceUnit) {
                displayPrice = PriceUtils.convertToCatty(displayPrice)
            }
            if (showRetail) {
                displayPrice = PriceUtils.estimateRetailPrice(displayPrice)
            }
            tvPrice.setText(PriceUtils.formatPrice(displayPrice))
            tvPrice.setTextColor(PriceUtils.getPriceLevelColor(p.priceLevel))

            // 趨勢
            tvTrend.setText(PriceUtils.getTrendArrow(p.trend))
            tvTrend.setTextColor(PriceUtils.getTrendColor(p.trend))

            // 單位
            tvUnit.setText(if ("catty" == priceUnit) "元/台斤" else "元/公斤")

            // 價格等級（圖示 + 文字 + 無障礙描述）
            val icon = PriceUtils.getPriceLevelIcon(p.priceLevel)
            val levelLabel = PriceUtils.getPriceLevelLabel(p.priceLevel)
            tvLevel.text = if (icon.isNotEmpty()) "$icon $levelLabel" else levelLabel
            tvLevel.setTextColor(PriceUtils.getPriceLevelColor(p.priceLevel))
            tvLevel.contentDescription = PriceUtils.getPriceLevelAccessibilityLabel(p.priceLevel)
            val bg = GradientDrawable()
            bg.setColor(PriceUtils.getPriceLevelBgColor(p.priceLevel))
            bg.cornerRadius = 20f
            tvLevel.background = bg

            // 收藏
            val isFav = p.cropCode != null && favorites.contains(p.cropCode)
            btnFav.setImageResource(
                if (isFav) R.drawable.ic_favorite_on else R.drawable.ic_favorite_off
            )
            btnFav.contentDescription = if (isFav) "取消收藏 ${p.cropName}" else "加入收藏 ${p.cropName}"
            btnFav.setOnClickListener(View.OnClickListener { v: View? -> listener.onFavoriteClick(p) })

            // 點擊
            itemView.setOnClickListener(View.OnClickListener { v: View? -> listener.onItemClick(p) })
        }
    }
}
