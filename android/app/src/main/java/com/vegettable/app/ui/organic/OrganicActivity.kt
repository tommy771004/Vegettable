package com.vegettable.app.ui.organic

import android.graphics.Color
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
import com.vegettable.app.model.OrganicPrice
import com.vegettable.app.network.ApiClient.Companion.instance
import com.vegettable.app.ui.adapter.SkeletonAdapter
import com.vegettable.app.util.PriceUtils
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response

class OrganicActivity : AppCompatActivity() {

    private lateinit var rv: RecyclerView
    private lateinit var rvSkeleton: RecyclerView
    private lateinit var swipeRefresh: SwipeRefreshLayout
    private lateinit var chipGroup: ChipGroup
    private lateinit var etSearch: TextInputEditText
    private lateinit var layoutError: View
    private lateinit var tvError: TextView
    private lateinit var adapter: OrganicAdapter

    private val certTypes = listOf("全部", "有機", "產銷履歷")
    private var allItems: List<OrganicPrice> = emptyList()
    private var selectedCert = "全部"
    private var searchQuery = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_organic)

        findViewById<View>(R.id.btn_back).setOnClickListener { finish() }

        rv = findViewById(R.id.rv_organic)
        rvSkeleton = findViewById(R.id.rv_skeleton)
        swipeRefresh = findViewById(R.id.swipe_refresh)
        chipGroup = findViewById(R.id.chip_group_cert)
        etSearch = findViewById(R.id.et_search)
        layoutError = findViewById(R.id.layout_error)
        tvError = findViewById(R.id.tv_error)

        rv.layoutManager = LinearLayoutManager(this)
        adapter = OrganicAdapter()
        rv.adapter = adapter

        rvSkeleton.layoutManager = LinearLayoutManager(this)
        rvSkeleton.adapter = SkeletonAdapter(8)

        swipeRefresh.setColorSchemeColor(getColor(R.color.primary))
        swipeRefresh.setOnRefreshListener { loadData() }

        findViewById<View>(R.id.btn_retry).setOnClickListener { loadData() }

        setupCertChips()

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

    private fun setupCertChips() {
        chipGroup.removeAllViews()
        certTypes.forEach { cert ->
            val chip = Chip(this, null, com.google.android.material.R.attr.chipStyle)
            chip.text = cert
            chip.isCheckable = true
            chip.isChecked = cert == selectedCert
            chip.setOnCheckedChangeListener { _, isChecked ->
                if (isChecked) {
                    selectedCert = cert
                    applyFilter()
                }
            }
            chipGroup.addView(chip)
        }
    }

    private fun loadData() {
        if (!swipeRefresh.isRefreshing) {
            rvSkeleton.visibility = View.VISIBLE
            rv.visibility = View.GONE
        }
        layoutError.visibility = View.GONE

        instance!!.api.getOrganicPrices(null, null)!!
            .enqueue(object : Callback<ApiResponse<MutableList<OrganicPrice?>?>?> {
                override fun onResponse(
                    call: Call<ApiResponse<MutableList<OrganicPrice?>?>?>,
                    response: Response<ApiResponse<MutableList<OrganicPrice?>?>?>
                ) {
                    swipeRefresh.isRefreshing = false
                    rvSkeleton.visibility = View.GONE

                    if (response.isSuccessful && response.body()?.success == true && response.body()?.data != null) {
                        allItems = response.body()!!.data!!.filterNotNull()
                        applyFilter()
                        rv.visibility = View.VISIBLE
                    } else {
                        showError("無法取得有機行情資料")
                    }
                }

                override fun onFailure(call: Call<ApiResponse<MutableList<OrganicPrice?>?>?>, t: Throwable) {
                    swipeRefresh.isRefreshing = false
                    rvSkeleton.visibility = View.GONE
                    showError("網路連線不穩定")
                }
            })
    }

    private fun applyFilter() {
        val filtered = allItems.filter { item ->
            val matchesCert = selectedCert == "全部" || item.certType == selectedCert
            val matchesSearch = searchQuery.isEmpty() || item.cropName.contains(searchQuery)
            matchesCert && matchesSearch
        }
        adapter.setItems(filtered)
    }

    private fun showError(msg: String) {
        tvError.text = msg
        layoutError.visibility = View.VISIBLE
        rv.visibility = View.GONE
    }
}

class OrganicAdapter : RecyclerView.Adapter<OrganicAdapter.ViewHolder>() {
    private var items: List<OrganicPrice> = emptyList()

    fun setItems(newItems: List<OrganicPrice>) {
        items = newItems
        notifyDataSetChanged()
    }

    inner class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val tvCropName: TextView = itemView.findViewById(R.id.tv_crop_name)
        val tvCertType: TextView = itemView.findViewById(R.id.tv_cert_type)
        val tvMarket: TextView = itemView.findViewById(R.id.tv_market_name)
        val tvDate: TextView = itemView.findViewById(R.id.tv_trans_date)
        val tvPrice: TextView = itemView.findViewById(R.id.tv_price)
        val tvPremium: TextView = itemView.findViewById(R.id.tv_premium)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_organic, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val item = items[position]
        holder.tvCropName.text = item.cropName
        holder.tvCertType.text = item.certType
        holder.tvMarket.text = item.marketName
        holder.tvDate.text = item.transDate
        holder.tvPrice.text = PriceUtils.formatPrice(item.avgPrice)

        if (item.premiumPercent != null) {
            val pct = item.premiumPercent
            holder.tvPremium.text = String.format("%+.1f%%", pct)
            holder.tvPremium.setTextColor(if (pct >= 0) Color.parseColor("#E53935") else Color.parseColor("#2E7D32"))
            holder.tvPremium.visibility = View.VISIBLE
        } else {
            holder.tvPremium.visibility = View.GONE
        }
    }

    override fun getItemCount() = items.size
}
