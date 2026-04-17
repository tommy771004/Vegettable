package com.vegettable.app.ui.livestock

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
import com.google.android.material.textfield.TextInputEditText
import com.vegettable.app.R
import com.vegettable.app.model.ApiResponse
import com.vegettable.app.model.LivestockPrice
import com.vegettable.app.network.ApiClient.Companion.instance
import com.vegettable.app.ui.adapter.SkeletonAdapter
import com.vegettable.app.util.PriceUtils
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response

class LivestockActivity : AppCompatActivity() {

    private lateinit var rv: RecyclerView
    private lateinit var rvSkeleton: RecyclerView
    private lateinit var swipeRefresh: SwipeRefreshLayout
    private lateinit var etSearch: TextInputEditText
    private lateinit var layoutError: View
    private lateinit var tvError: TextView
    private lateinit var tvEmpty: TextView
    private lateinit var adapter: LivestockAdapter

    private var allItems: List<LivestockPrice> = emptyList()
    private var searchQuery = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_livestock)

        findViewById<View>(R.id.btn_back).setOnClickListener { finish() }

        rv = findViewById(R.id.rv_livestock)
        rvSkeleton = findViewById(R.id.rv_skeleton)
        swipeRefresh = findViewById(R.id.swipe_refresh)
        etSearch = findViewById(R.id.et_search)
        layoutError = findViewById(R.id.layout_error)
        tvError = findViewById(R.id.tv_error)
        tvEmpty = findViewById(R.id.tv_empty)

        rv.layoutManager = LinearLayoutManager(this)
        adapter = LivestockAdapter()
        rv.adapter = adapter

        rvSkeleton.layoutManager = LinearLayoutManager(this)
        rvSkeleton.adapter = SkeletonAdapter(8)

        swipeRefresh.setColorSchemeColors(getColor(R.color.primary))
        swipeRefresh.setProgressBackgroundColorSchemeResource(R.color.surface)
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

        instance!!.api.getLivestockPrices(null)!!
            .enqueue(object : Callback<ApiResponse<MutableList<LivestockPrice?>?>?> {
                override fun onResponse(
                    call: Call<ApiResponse<MutableList<LivestockPrice?>?>?>,
                    response: Response<ApiResponse<MutableList<LivestockPrice?>?>?>
                ) {
                    swipeRefresh.isRefreshing = false
                    rvSkeleton.visibility = View.GONE

                    if (response.isSuccessful && response.body()?.success == true && response.body()?.data != null) {
                        allItems = response.body()!!.data!!.filterNotNull()
                        applyFilter()
                        rv.visibility = View.VISIBLE
                    } else {
                        showError("無法取得畜產品行情")
                    }
                }

                override fun onFailure(call: Call<ApiResponse<MutableList<LivestockPrice?>?>?>, t: Throwable) {
                    swipeRefresh.isRefreshing = false
                    rvSkeleton.visibility = View.GONE
                    showError("網路連線不穩定")
                }
            })
    }

    private fun applyFilter() {
        val filtered = if (searchQuery.isEmpty()) allItems
        else allItems.filter { it.livestockName.contains(searchQuery, ignoreCase = true) }
        adapter.setItems(filtered)
        tvEmpty.visibility = if (filtered.isEmpty() && allItems.isNotEmpty()) View.VISIBLE else View.GONE
    }

    private fun showError(msg: String) {
        tvError.text = msg
        layoutError.visibility = View.VISIBLE
        rv.visibility = View.GONE
    }
}

class LivestockAdapter : RecyclerView.Adapter<LivestockAdapter.ViewHolder>() {
    private var items: List<LivestockPrice> = emptyList()

    fun setItems(newItems: List<LivestockPrice>) {
        items = newItems
        notifyDataSetChanged()
    }

    inner class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val tvName: TextView = itemView.findViewById(R.id.tv_livestock_name)
        val tvMarket: TextView = itemView.findViewById(R.id.tv_market_name)
        val tvDate: TextView = itemView.findViewById(R.id.tv_trans_date)
        val tvPrice: TextView = itemView.findViewById(R.id.tv_price)
        val tvTrend: TextView = itemView.findViewById(R.id.tv_trend)
        val tvHeadCount: TextView = itemView.findViewById(R.id.tv_head_count)
        val tvAvgWeight: TextView = itemView.findViewById(R.id.tv_avg_weight)
        val tvUpper: TextView = itemView.findViewById(R.id.tv_upper)
        val tvLower: TextView = itemView.findViewById(R.id.tv_lower)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_livestock, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val item = items[position]
        holder.tvName.text = item.livestockName
        holder.tvMarket.text = item.marketName
        holder.tvDate.text = item.transDate
        holder.tvPrice.text = PriceUtils.formatPrice(item.avgPrice)
        holder.tvPrice.setTextColor(PriceUtils.getTrendColor(item.trend))
        holder.tvTrend.text = PriceUtils.getTrendArrow(item.trend)
        holder.tvTrend.setTextColor(PriceUtils.getTrendColor(item.trend))
        holder.tvHeadCount.text = "${item.headCount} 頭"
        holder.tvAvgWeight.text = "均重 ${String.format("%.1f", item.avgWeight)} kg"
        holder.tvUpper.text = "↑${PriceUtils.formatPrice(item.upperPrice)}"
        holder.tvLower.text = "↓${PriceUtils.formatPrice(item.lowerPrice)}"
    }

    override fun getItemCount() = items.size
}
