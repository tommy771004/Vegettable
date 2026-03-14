package com.vegettable.app.ui.aquatic

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
import com.vegettable.app.model.ApiResponse
import com.vegettable.app.model.AquaticPrice
import com.vegettable.app.network.ApiClient.Companion.instance
import com.vegettable.app.ui.adapter.SkeletonAdapter
import com.vegettable.app.util.PriceUtils
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response

class AquaticActivity : AppCompatActivity() {

    private lateinit var rv: RecyclerView
    private lateinit var rvSkeleton: RecyclerView
    private lateinit var swipeRefresh: SwipeRefreshLayout
    private lateinit var chipGroup: ChipGroup
    private lateinit var etSearch: TextInputEditText
    private lateinit var layoutError: View
    private lateinit var tvError: TextView
    private lateinit var adapter: AquaticAdapter

    private var allItems: List<AquaticPrice> = emptyList()
    private var selectedMarket = "全部"
    private var searchQuery = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_aquatic)

        findViewById<View>(R.id.btn_back).setOnClickListener { finish() }

        rv = findViewById(R.id.rv_aquatic)
        rvSkeleton = findViewById(R.id.rv_skeleton)
        swipeRefresh = findViewById(R.id.swipe_refresh)
        chipGroup = findViewById(R.id.chip_group_market)
        etSearch = findViewById(R.id.et_search)
        layoutError = findViewById(R.id.layout_error)
        tvError = findViewById(R.id.tv_error)

        rv.layoutManager = LinearLayoutManager(this)
        adapter = AquaticAdapter()
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

        instance!!.api.getFishPrices(null, null)!!
            .enqueue(object : Callback<ApiResponse<MutableList<AquaticPrice?>?>?> {
                override fun onResponse(
                    call: Call<ApiResponse<MutableList<AquaticPrice?>?>?>,
                    response: Response<ApiResponse<MutableList<AquaticPrice?>?>?>
                ) {
                    swipeRefresh.isRefreshing = false
                    rvSkeleton.visibility = View.GONE

                    if (response.isSuccessful && response.body()?.success == true && response.body()?.data != null) {
                        allItems = response.body()!!.data!!.filterNotNull()
                        updateMarketChips()
                        applyFilter()
                        rv.visibility = View.VISIBLE
                    } else {
                        showError("無法取得漁產品行情")
                    }
                }

                override fun onFailure(call: Call<ApiResponse<MutableList<AquaticPrice?>?>?>, t: Throwable) {
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
            val matchesSearch = searchQuery.isEmpty() || item.fishName.contains(searchQuery)
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

class AquaticAdapter : RecyclerView.Adapter<AquaticAdapter.ViewHolder>() {
    private var items: List<AquaticPrice> = emptyList()

    fun setItems(newItems: List<AquaticPrice>) {
        items = newItems
        notifyDataSetChanged()
    }

    inner class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val tvFishName: TextView = itemView.findViewById(R.id.tv_fish_name)
        val tvMarket: TextView = itemView.findViewById(R.id.tv_market_name)
        val tvDate: TextView = itemView.findViewById(R.id.tv_trans_date)
        val tvPrice: TextView = itemView.findViewById(R.id.tv_price)
        val tvTrend: TextView = itemView.findViewById(R.id.tv_trend)
        val tvVolume: TextView = itemView.findViewById(R.id.tv_volume)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_aquatic, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val item = items[position]
        holder.tvFishName.text = item.fishName
        holder.tvMarket.text = item.marketName
        holder.tvDate.text = item.transDate
        holder.tvPrice.text = PriceUtils.formatPrice(item.avgPrice)
        holder.tvPrice.setTextColor(PriceUtils.getTrendColor(item.trend))
        holder.tvTrend.text = PriceUtils.getTrendArrow(item.trend)
        holder.tvTrend.setTextColor(PriceUtils.getTrendColor(item.trend))
        holder.tvVolume.text = "量: ${item.volume.toInt()} 公斤"
    }

    override fun getItemCount() = items.size
}
