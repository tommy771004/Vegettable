package com.vegettable.app.ui.map

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.CompoundButton
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import com.google.android.material.chip.Chip
import com.google.android.material.chip.ChipGroup
import com.vegettable.app.R
import com.vegettable.app.model.ApiResponse
import com.vegettable.app.model.Market
import com.vegettable.app.network.ApiClient
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response

class MapActivity : AppCompatActivity() {
    private var adapter: MarketAdapter? = null
    private var allMarkets: MutableList<Market> = mutableListOf()
    private var selectedRegion: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_map)

        findViewById<View>(R.id.btn_back).setOnClickListener { finish() }

        val rvMarkets = findViewById<RecyclerView>(R.id.rv_markets)
        rvMarkets.layoutManager = LinearLayoutManager(this)
        adapter = MarketAdapter()
        rvMarkets.adapter = adapter

        setupRegionChips()
        loadMarketsFromApi()
    }

    private fun loadMarketsFromApi() {
        ApiClient.instance?.api?.markets
            ?.enqueue(object : Callback<ApiResponse<MutableList<Market?>?>?> {
                override fun onResponse(
                    call: Call<ApiResponse<MutableList<Market?>?>?>,
                    response: Response<ApiResponse<MutableList<Market?>?>?>
                ) {
                    if (response.isSuccessful && response.body()?.isSuccess == true) {
                        val markets = response.body()?.data?.filterNotNull()?.toMutableList()
                            ?: mutableListOf()
                        allMarkets = markets
                        filterMarkets()
                    } else {
                        Toast.makeText(this@MapActivity, "市場資料載入失敗", Toast.LENGTH_SHORT).show()
                    }
                }

                override fun onFailure(call: Call<ApiResponse<MutableList<Market?>?>?>, t: Throwable) {
                    Toast.makeText(this@MapActivity, "網路連線異常", Toast.LENGTH_SHORT).show()
                }
            })
    }

    private fun setupRegionChips() {
        val group = findViewById<ChipGroup>(R.id.chip_group_region)
        val regions = arrayOf("全部", "北部", "中部", "南部", "東部")
        for (r in regions) {
            val chip = Chip(this)
            chip.text = r
            chip.isCheckable = true
            if ("全部" == r) chip.isChecked = true
            chip.setOnCheckedChangeListener { btn: CompoundButton, checked: Boolean ->
                if (checked) {
                    selectedRegion = if ("全部" == btn.text.toString()) null else btn.text.toString()
                    filterMarkets()
                }
            }
            group.addView(chip)
        }
    }

    private fun filterMarkets() {
        val filtered = if (selectedRegion == null) {
            allMarkets.toMutableList()
        } else {
            allMarkets.filter { it.region == selectedRegion }.toMutableList()
        }
        adapter?.setItems(filtered)
    }

    // ─── Adapter ────────────────────────────────────────────
    internal inner class MarketAdapter : RecyclerView.Adapter<MarketAdapter.VH>() {
        private var items: MutableList<Market> = mutableListOf()

        fun setItems(newItems: MutableList<Market>) {
            val diff = DiffUtil.calculateDiff(object : DiffUtil.Callback() {
                override fun getOldListSize() = items.size
                override fun getNewListSize() = newItems.size
                override fun areItemsTheSame(o: Int, n: Int) = items[o].marketCode == newItems[n].marketCode
                override fun areContentsTheSame(o: Int, n: Int) = items[o].marketName == newItems[n].marketName
            })
            items = newItems
            diff.dispatchUpdatesTo(this)
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
            val v = LayoutInflater.from(parent.context).inflate(R.layout.item_market, parent, false)
            return VH(v)
        }

        override fun onBindViewHolder(h: VH, pos: Int) {
            val m = items[pos]
            h.tvName.text = (m.marketName ?: "") + "果菜批發市場"
            h.tvAddress.text = m.address ?: ""
            h.tvRegion.text = m.region ?: ""
            h.btnNavigate.setOnClickListener {
                val address = m.address ?: return@setOnClickListener
                val uri = Uri.parse("geo:${m.latitude},${m.longitude}?q=${Uri.encode(address)}")
                startActivity(Intent(Intent.ACTION_VIEW, uri))
            }
        }

        override fun getItemCount() = items.size

        inner class VH(v: View) : RecyclerView.ViewHolder(v) {
            val tvName: TextView = v.findViewById(R.id.tv_market_name)
            val tvAddress: TextView = v.findViewById(R.id.tv_address)
            val tvRegion: TextView = v.findViewById(R.id.tv_region)
            val btnNavigate: MaterialButton = v.findViewById(R.id.btn_navigate)
        }
    }
}
