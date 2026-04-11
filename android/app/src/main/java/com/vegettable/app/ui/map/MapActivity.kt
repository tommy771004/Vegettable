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
import androidx.core.content.ContextCompat
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
import org.osmdroid.config.Configuration
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.GeoPoint
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.Marker
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response

class MapActivity : AppCompatActivity() {
    private var adapter: MarketAdapter? = null
    private var allMarkets: MutableList<Market> = mutableListOf()
    private var selectedRegion: String? = null
    private var showingMap = false

    private lateinit var mapView: MapView
    private lateinit var rvMarkets: RecyclerView
    private lateinit var btnToggle: MaterialButton

    override fun onCreate(savedInstanceState: Bundle?) {
        // osmdroid 快取設定（必須在 super 之前）
        Configuration.getInstance().load(applicationContext,
            androidx.preference.PreferenceManager.getDefaultSharedPreferences(applicationContext))
        Configuration.getInstance().userAgentValue = packageName

        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_map)

        findViewById<View>(R.id.btn_back).setOnClickListener { finish() }

        mapView = findViewById(R.id.map_view)
        rvMarkets = findViewById(R.id.rv_markets)
        btnToggle = findViewById(R.id.btn_toggle_view)

        setupMap()
        setupRecyclerView()
        setupRegionChips()
        setupToggleButton()
        loadMarketsFromApi()
    }

    private fun setupMap() {
        mapView.setTileSource(TileSourceFactory.MAPNIK)
        mapView.setMultiTouchControls(true)
        mapView.controller.setZoom(8.0)
        // 台灣中心點
        mapView.controller.setCenter(GeoPoint(23.6, 120.9))
    }

    private fun setupRecyclerView() {
        rvMarkets.layoutManager = LinearLayoutManager(this)
        adapter = MarketAdapter()
        rvMarkets.adapter = adapter
    }

    private fun setupToggleButton() {
        btnToggle.setOnClickListener {
            showingMap = !showingMap
            if (showingMap) {
                mapView.visibility = View.VISIBLE
                rvMarkets.visibility = View.GONE
                btnToggle.text = "列表"
                addMapMarkers(filteredMarkets())
            } else {
                mapView.visibility = View.GONE
                rvMarkets.visibility = View.VISIBLE
                btnToggle.text = "地圖"
            }
        }
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

    private fun filteredMarkets(): MutableList<Market> {
        return if (selectedRegion == null) {
            allMarkets.toMutableList()
        } else {
            allMarkets.filter { it.region == selectedRegion }.toMutableList()
        }
    }

    private fun filterMarkets() {
        val filtered = filteredMarkets()
        adapter?.setItems(filtered)
        if (showingMap) {
            addMapMarkers(filtered)
        }
    }

    private fun addMapMarkers(markets: List<Market>) {
        mapView.overlays.clear()
        for (m in markets) {
            val lat = m.latitude ?: continue
            val lng = m.longitude ?: continue
            if (lat == 0.0 && lng == 0.0) continue

            val marker = Marker(mapView)
            marker.position = GeoPoint(lat, lng)
            marker.title = (m.marketName ?: "") + "果菜批發市場"
            marker.snippet = m.address ?: ""
            marker.setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM)
            marker.setOnMarkerClickListener { mk, _ ->
                mk.showInfoWindow()
                true
            }
            mapView.overlays.add(marker)
        }

        // 有市場時縮放到合適範圍
        if (markets.isNotEmpty()) {
            val validMarkets = markets.filter {
                (it.latitude ?: 0.0) != 0.0 || (it.longitude ?: 0.0) != 0.0
            }
            if (validMarkets.size == 1) {
                val m = validMarkets.first()
                mapView.controller.animateTo(GeoPoint(m.latitude!!, m.longitude!!))
                mapView.controller.setZoom(14.0)
            } else if (validMarkets.size > 1) {
                mapView.controller.setZoom(8.0)
                mapView.controller.setCenter(GeoPoint(23.6, 120.9))
            }
        }
        mapView.invalidate()
    }

    override fun onResume() {
        super.onResume()
        mapView.onResume()
    }

    override fun onPause() {
        super.onPause()
        mapView.onPause()
    }

    override fun onDestroy() {
        super.onDestroy()
        mapView.onDetach()
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
