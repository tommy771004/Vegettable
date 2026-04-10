package com.vegettable.app.ui.compare

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.textfield.TextInputEditText
import com.vegettable.app.R
import com.vegettable.app.model.ApiResponse
import com.vegettable.app.model.MarketPrice
import com.vegettable.app.network.ApiClient.Companion.instance
import com.vegettable.app.util.PriceUtils
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response

class CompareActivity : AppCompatActivity() {
    private var etCropName: TextInputEditText? = null
    private var rvCompare: RecyclerView? = null
    private var progressBar: ProgressBar? = null
    private var layoutError: LinearLayout? = null
    private var tvError: TextView? = null
    private var adapter: CompareAdapter? = null
    private var lastCropName: String? = null
    private var retryCount = 0
    private val retryHandler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_compare)

        findViewById<View?>(R.id.btn_back).setOnClickListener { finish() }

        etCropName = findViewById(R.id.et_crop_name)
        rvCompare = findViewById(R.id.rv_compare)
        progressBar = findViewById(R.id.progress_bar)
        layoutError = findViewById(R.id.layout_error)
        tvError = findViewById(R.id.tv_error)

        rvCompare?.layoutManager = LinearLayoutManager(this)
        adapter = CompareAdapter()
        rvCompare?.adapter = adapter

        findViewById<View?>(R.id.btn_retry).setOnClickListener {
            if (!lastCropName.isNullOrEmpty()) {
                val delay = when (retryCount) {
                    0 -> 0L
                    1 -> 2000L
                    2 -> 4000L
                    else -> 8000L
                }
                retryCount++
                retryHandler.postDelayed({ comparePrices(lastCropName) }, delay)
            }
        }

        etCropName?.setOnEditorActionListener { v, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                val crop = etCropName?.text.toString().trim()
                if (crop.isNotEmpty()) {
                    val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
                    imm.hideSoftInputFromWindow(v.windowToken, 0)
                    comparePrices(crop)
                }
                true
            } else {
                false
            }
        }
    }

    private fun comparePrices(cropName: String?) {
        lastCropName = cropName
        progressBar?.visibility = View.VISIBLE
        layoutError?.visibility = View.GONE
        rvCompare?.visibility = View.GONE

        instance?.api?.compareMarketPrices(cropName, null)?.enqueue(object : Callback<ApiResponse<MutableList<MarketPrice?>?>?> {
            override fun onResponse(
                call: Call<ApiResponse<MutableList<MarketPrice?>?>?>,
                response: Response<ApiResponse<MutableList<MarketPrice?>?>?>
            ) {
                progressBar?.visibility = View.GONE
                val body = response.body()
                if (response.isSuccessful && body != null && body.isSuccess && body.data != null) {
                    val marketPrices = body.data?.filterNotNull()?.toMutableList() ?: mutableListOf()
                    adapter?.setItems(marketPrices)
                    retryCount = 0
                    if (marketPrices.isEmpty()) {
                        showError("找不到「${lastCropName}」的市場比價資料")
                    } else {
                        rvCompare?.visibility = View.VISIBLE
                    }
                } else {
                    showError("無法取得比價資料")
                }
            }

            override fun onFailure(
                call: Call<ApiResponse<MutableList<MarketPrice?>?>?>,
                t: Throwable
            ) {
                progressBar?.visibility = View.GONE
                showError("網路錯誤: " + t.message)
            }
        })
    }

    private fun showError(message: String?) {
        tvError?.text = message
        layoutError?.visibility = View.VISIBLE
    }

    // ─── Adapter ────────────────────────────────────────────
    internal class CompareAdapter : RecyclerView.Adapter<CompareAdapter.VH>() {
        private var items: MutableList<MarketPrice> = ArrayList()

        fun setItems(items: MutableList<MarketPrice>) {
            this.items = items
            notifyDataSetChanged()
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
            val v = LayoutInflater.from(parent.context)
                .inflate(R.layout.item_compare, parent, false)
            return VH(v)
        }

        override fun onBindViewHolder(h: VH, pos: Int) {
            val mp = items[pos]
            h.tvMarketName.text = mp.marketName
            h.tvDate.text = mp.transDate
            h.tvAvgPrice.text = PriceUtils.formatPrice(mp.avgPrice) + " 元/公斤"
            h.tvPriceRange.text = (PriceUtils.formatPrice(mp.lowerPrice) + " ~ " + PriceUtils.formatPrice(mp.upperPrice))
        }

        override fun getItemCount(): Int {
            return items.size
        }

        internal class VH(v: View) : RecyclerView.ViewHolder(v) {
            var tvMarketName: TextView = v.findViewById(R.id.tv_market_name)
            var tvDate: TextView = v.findViewById(R.id.tv_date)
            var tvAvgPrice: TextView = v.findViewById(R.id.tv_avg_price)
            var tvPriceRange: TextView = v.findViewById(R.id.tv_price_range)
        }
    }
}
