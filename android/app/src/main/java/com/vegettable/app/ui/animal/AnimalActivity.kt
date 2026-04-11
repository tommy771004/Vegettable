package com.vegettable.app.ui.animal

import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import com.google.android.material.chip.Chip
import com.google.android.material.chip.ChipGroup
import com.google.android.material.textfield.TextInputEditText
import com.vegettable.app.R
import com.vegettable.app.model.AnimalPrice
import com.vegettable.app.model.ApiResponse
import com.vegettable.app.network.ApiClient.Companion.instance
import com.vegettable.app.ui.adapter.SkeletonAdapter
import com.vegettable.app.util.PriceUtils
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response

class AnimalActivity : AppCompatActivity() {

    private lateinit var rv: RecyclerView
    private lateinit var rvSkeleton: RecyclerView
    private lateinit var swipeRefresh: SwipeRefreshLayout
    private lateinit var chipGroup: ChipGroup
    private lateinit var etSearch: TextInputEditText
    private lateinit var layoutError: View
    private lateinit var tvError: TextView
    private lateinit var adapter: AnimalAdapter

    private var allItems: List<AnimalPrice> = emptyList()
    private var selectedMarket = "全部"
    private var searchQuery = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_animal)

        findViewById<View>(R.id.btn_back).setOnClickListener { finish() }

        rv = findViewById(R.id.rv_animal)
        rvSkeleton = findViewById(R.id.rv_skeleton)
        swipeRefresh = findViewById(R.id.swipe_refresh)
        chipGroup = findViewById(R.id.chip_group_market)
        etSearch = findViewById(R.id.et_search)
        layoutError = findViewById(R.id.layout_error)
        tvError = findViewById(R.id.tv_error)

        rv.layoutManager = LinearLayoutManager(this)
        adapter = AnimalAdapter()
        rv.adapter = adapter

        rvSkeleton.layoutManager = LinearLayoutManager(this)
        rvSkeleton.adapter = SkeletonAdapter(8)

        swipeRefresh.setColorSchemeColor(getColor(R.color.primary))
        swipeRefresh.setOnRefreshListener { loadData() }

        findViewById<View>(R.id.btn_retry).setOnClickListener { loadData() }

        etSearch.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                searchQuery = s?.toString() ?: ""
                applyFilter()
            }
        })

        loadData()
    }

    private fun loadData() {
        if (!swipeRefresh.isRefreshing) {
            rvSkeleton.visibility = View.VISIBLE
            rv.visibility = View.GONE
        }
        layoutError.visibility = View.GONE

        instance!!.api.getAnimalPrices(null, null)!!
            .enqueue(object : Callback<ApiResponse<MutableList<AnimalPrice?>?>?> {
                override fun onResponse(
                    call: Call<ApiResponse<MutableList<AnimalPrice?>?>?>,
                    response: Response<ApiResponse<MutableList<AnimalPrice?>?>?>
                ) {
                    swipeRefresh.isRefreshing = false
                    rvSkeleton.visibility = View.GONE

                    if (response.isSuccessful && response.body()?.success == true && response.body()?.data != null) {
                        allItems = response.body()!!.data!!.filterNotNull()
                        updateMarketChips()
                        applyFilter()
                        rv.visibility = View.VISIBLE
                    } else {
                        showError("無法取得毛豬行情")
                    }
                }

                override fun onFailure(call: Call<ApiResponse<MutableList<AnimalPrice?>?>?>, t: Throwable) {
                    swipeRefresh.isRefreshing = false
                    rvSkeleton.visibility = View.GONE
                    showError("網路連線不穩定")
                }
            })
    }

    private fun updateMarketChips() {
        val markets = listOf("全部") + allItems.map { it.marketName }.distinct().sorted()
        chipGroup.removeAllViews()
        markets.forEach { market ->
            val chip = Chip(this, null, com.google.android.material.R.attr.chipStyle)
            chip.text = market
            chip.isCheckable = true
            chip.isChecked = market == selectedMarket
            chip.setOnCheckedChangeListener { _, isChecked ->
                if (isChecked) {
                    selectedMarket = market
                    applyFilter()
                }
            }
            chipGroup.addView(chip)
        }
    }

    private fun applyFilter() {
        val filtered = allItems.filter { item ->
            val matchesMarket = selectedMarket == "全部" || item.marketName == selectedMarket
            val matchesSearch = searchQuery.isEmpty() ||
                item.productName.contains(searchQuery, ignoreCase = true)
            matchesMarket && matchesSearch
        }
        adapter.setItems(filtered)
    }

    private fun showError(msg: String) {
        tvError.text = msg
        layoutError.visibility = View.VISIBLE
        rv.visibility = View.GONE
    }
}

class AnimalAdapter : RecyclerView.Adapter<AnimalAdapter.ViewHolder>() {
    private var items: List<AnimalPrice> = emptyList()

    fun setItems(newItems: List<AnimalPrice>) {
        items = newItems
        notifyDataSetChanged()
    }

    inner class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val tvProductName: TextView = itemView.findViewById(R.id.tv_product_name)
        val tvMarketName: TextView = itemView.findViewById(R.id.tv_market_name)
        val tvTransDate: TextView = itemView.findViewById(R.id.tv_trans_date)
        val tvHeadCount: TextView = itemView.findViewById(R.id.tv_head_count)
        val tvAvgWeight: TextView = itemView.findViewById(R.id.tv_avg_weight)
        val tvPrice: TextView = itemView.findViewById(R.id.tv_price)
        val tvTrend: TextView = itemView.findViewById(R.id.tv_trend)
        val tvPriceRange: TextView = itemView.findViewById(R.id.tv_price_range)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_animal, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val item = items[position]
        holder.tvProductName.text = item.productName
        holder.tvMarketName.text = item.marketName
        holder.tvTransDate.text = item.transDate
        holder.tvHeadCount.text = "頭數: ${item.headCount}"
        holder.tvAvgWeight.text = "均重: ${"%.1f".format(item.avgWeight)} kg"
        holder.tvPrice.text = PriceUtils.formatPrice(item.avgPrice)
        holder.tvPrice.setTextColor(PriceUtils.getTrendColor(item.trend))
        holder.tvTrend.text = PriceUtils.getTrendArrow(item.trend)
        holder.tvTrend.setTextColor(PriceUtils.getTrendColor(item.trend))
        holder.tvPriceRange.text = "${"%.0f".format(item.lowerPrice)}–${"%.0f".format(item.upperPrice)}"
    }

    override fun getItemCount() = items.size
}
