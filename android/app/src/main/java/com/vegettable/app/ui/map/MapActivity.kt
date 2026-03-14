package com.vegettable.app.ui.map

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.CompoundButton
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import com.google.android.material.chip.Chip
import com.google.android.material.chip.ChipGroup
import com.vegettable.app.R
import java.util.Arrays

class MapActivity : AppCompatActivity() {
    private var adapter: MarketAdapter? = null
    private var selectedRegion: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {

        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_map)

        findViewById<View?>(R.id.btn_back).setOnClickListener(View.OnClickListener { v: View? -> finish() })

        val rvMarkets = findViewById<RecyclerView>(R.id.rv_markets)
        rvMarkets.setLayoutManager(LinearLayoutManager(this))
        adapter = MarketAdapter()
        rvMarkets.setAdapter(adapter)
        adapter!!.setItems(ALL_MARKETS)

        setupRegionChips()
    }

    private fun setupRegionChips() {
        val group = findViewById<ChipGroup>(R.id.chip_group_region)
        val regions = arrayOf<String?>("全部", "北部", "中部", "南部", "東部")
        for (r in regions) {
            val chip = Chip(this)
            chip.setText(r)
            chip.setCheckable(true)
            if ("全部" == r) chip.setChecked(true)
            chip.setOnCheckedChangeListener(CompoundButton.OnCheckedChangeListener { btn: CompoundButton?, checked: Boolean ->
                if (checked) {
                    selectedRegion =
                        if ("全部" == btn!!.getText().toString()) null else btn.getText()
                            .toString()
                    filterMarkets()
                }
            })
            group.addView(chip)
        }
    }

    private fun filterMarkets() {
        if (selectedRegion == null) {
            adapter!!.setItems(ALL_MARKETS)
        } else {
            val filtered: MutableList<MarketItem> = ArrayList<MarketItem>()
            for (m in ALL_MARKETS) {
                if (selectedRegion == m.region) {
                    filtered.add(m)
                }
            }
            adapter!!.setItems(filtered)
        }
    }

    // ─── Data ────────────────────────────────────────────────
    internal class MarketItem(
        val name: String?,
        val address: String?,
        val region: String?,
        val lat: Double,
        val lng: Double
    )

    // ─── Adapter ────────────────────────────────────────────
    internal inner class MarketAdapter : RecyclerView.Adapter<MarketAdapter.VH?>() {
        private var items: MutableList<MarketItem> = ArrayList<MarketItem>()

        fun setItems(items: MutableList<MarketItem>) {
            this.items = items
            notifyDataSetChanged()
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
            val v = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_market, parent, false)
            return VH(v)
        }

        override fun onBindViewHolder(h: VH, pos: Int) {
            val m = items.get(pos)
            h.tvName.setText(m.name + "果菜批發市場")
            h.tvAddress.setText(m.address)
            h.tvRegion.setText(m.region)
            h.btnNavigate.setOnClickListener(View.OnClickListener { v: View? ->
                val uri = Uri.parse("geo:" + m.lat + "," + m.lng + "?q=" + Uri.encode(m.address))
                val intent = Intent(Intent.ACTION_VIEW, uri)
                startActivity(intent)
            })
        }

        override fun getItemCount(): Int {
            return items.size
        }

        internal inner class VH(v: View) : RecyclerView.ViewHolder(v) {
            var tvName: TextView
            var tvAddress: TextView
            var tvRegion: TextView
            var btnNavigate: MaterialButton

            init {
                tvName = v.findViewById<TextView>(R.id.tv_market_name)
                tvAddress = v.findViewById<TextView>(R.id.tv_address)
                tvRegion = v.findViewById<TextView>(R.id.tv_region)
                btnNavigate = v.findViewById<MaterialButton>(R.id.btn_navigate)
            }
        }
    }

    companion object {
        // 批發市場資料
        private val ALL_MARKETS: MutableList<MarketItem> = Arrays.asList<MarketItem?>(
            MarketItem("台北一", "台北市萬華區萬大路533號", "北部", 25.0258, 121.5010),
            MarketItem("台北二", "台北市中山區民族東路336號", "北部", 25.0690, 121.5375),
            MarketItem("三重", "新北市三重區大同北路107號", "北部", 25.0620, 121.4872),
            MarketItem("桃園", "桃園市桃園區中山路590號", "北部", 24.9917, 121.3125),
            MarketItem("台中", "台中市西屯區中清路350號", "中部", 24.1795, 120.6547),
            MarketItem("溪湖", "彰化縣溪湖鎮彰水路四段510號", "中部", 23.9617, 120.4793),
            MarketItem("西螺", "雲林縣西螺鎮九隆里延平路248號", "中部", 23.7983, 120.4602),
            MarketItem("嘉義", "嘉義市西區博愛路二段459號", "南部", 23.4817, 120.4343),
            MarketItem("台南", "台南市北區忠北街7號", "南部", 23.0125, 120.2153),
            MarketItem("鳳山", "高雄市鳳山區建國路三段39號", "南部", 22.6273, 120.3419),
            MarketItem("屏東", "屏東縣屏東市工業路9號", "南部", 22.6656, 120.4950),
            MarketItem("宜蘭", "宜蘭縣宜蘭市環市東路二段1號", "東部", 24.7469, 121.7515),
            MarketItem("花蓮", "花蓮縣花蓮市中華路100號", "東部", 23.9872, 121.6044)
        )
    }
}
