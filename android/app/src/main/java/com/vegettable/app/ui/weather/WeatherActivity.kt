package com.vegettable.app.ui.weather

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.CompoundButton
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import com.google.android.material.button.MaterialButton
import com.google.android.material.chip.Chip
import com.google.android.material.chip.ChipGroup
import com.vegettable.app.R
import com.vegettable.app.model.ApiResponse
import com.vegettable.app.model.WeatherObservation
import com.vegettable.app.network.ApiClient.Companion.instance
import com.vegettable.app.ui.adapter.SkeletonAdapter
import org.osmdroid.config.Configuration
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.GeoPoint
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.Marker
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response

class WeatherActivity : AppCompatActivity() {

    private lateinit var rv: RecyclerView
    private lateinit var rvSkeleton: RecyclerView
    private lateinit var swipeRefresh: SwipeRefreshLayout
    private lateinit var chipGroup: ChipGroup
    private lateinit var layoutError: View
    private lateinit var tvError: TextView
    private lateinit var adapter: WeatherAdapter
    private lateinit var mapView: MapView
    private lateinit var btnToggle: MaterialButton

    private var allItems: List<WeatherObservation> = emptyList()
    private var selectedCounty = "全部"
    private var showingMap = false

    override fun onCreate(savedInstanceState: Bundle?) {
        Configuration.getInstance().load(
            applicationContext,
            androidx.preference.PreferenceManager.getDefaultSharedPreferences(applicationContext)
        )
        Configuration.getInstance().userAgentValue = packageName

        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_weather)

        findViewById<View>(R.id.btn_back).setOnClickListener { finish() }

        rv = findViewById(R.id.rv_weather)
        rvSkeleton = findViewById(R.id.rv_skeleton)
        swipeRefresh = findViewById(R.id.swipe_refresh)
        chipGroup = findViewById(R.id.chip_group_county)
        layoutError = findViewById(R.id.layout_error)
        tvError = findViewById(R.id.tv_error)
        mapView = findViewById(R.id.map_view)
        btnToggle = findViewById(R.id.btn_toggle_view)

        rv.layoutManager = LinearLayoutManager(this)
        adapter = WeatherAdapter()
        rv.adapter = adapter

        rvSkeleton.layoutManager = LinearLayoutManager(this)
        rvSkeleton.adapter = SkeletonAdapter(8)

        mapView.setTileSource(TileSourceFactory.MAPNIK)
        mapView.setMultiTouchControls(true)
        mapView.controller.setZoom(8.0)
        mapView.controller.setCenter(GeoPoint(23.6, 120.9))

        swipeRefresh.setColorSchemeColors(getColor(R.color.primary))
        swipeRefresh.setProgressBackgroundColorSchemeResource(R.color.surface)
        swipeRefresh.setOnRefreshListener { loadData() }

        findViewById<View>(R.id.btn_retry).setOnClickListener { loadData() }

        btnToggle.setOnClickListener {
            showingMap = !showingMap
            if (showingMap) {
                mapView.visibility = View.VISIBLE
                swipeRefresh.visibility = View.GONE
                btnToggle.text = "列表"
                addMapMarkers(filteredItems())
            } else {
                mapView.visibility = View.GONE
                swipeRefresh.visibility = View.VISIBLE
                btnToggle.text = "地圖"
            }
        }

        loadData()
    }

    private fun loadData() {
        if (!swipeRefresh.isRefreshing) {
            rvSkeleton.visibility = View.VISIBLE
            rv.visibility = View.GONE
        }
        layoutError.visibility = View.GONE

        instance!!.api.getWeatherObservations(null)!!
            .enqueue(object : Callback<ApiResponse<MutableList<WeatherObservation?>?>?> {
                override fun onResponse(
                    call: Call<ApiResponse<MutableList<WeatherObservation?>?>?>,
                    response: Response<ApiResponse<MutableList<WeatherObservation?>?>?>
                ) {
                    swipeRefresh.isRefreshing = false
                    rvSkeleton.visibility = View.GONE

                    if (response.isSuccessful && response.body()?.success == true && response.body()?.data != null) {
                        allItems = response.body()!!.data!!.filterNotNull()
                        updateCountyChips()
                        applyFilter()
                        rv.visibility = View.VISIBLE
                    } else {
                        showError("無法取得氣象資料")
                    }
                }

                override fun onFailure(call: Call<ApiResponse<MutableList<WeatherObservation?>?>?>, t: Throwable) {
                    swipeRefresh.isRefreshing = false
                    rvSkeleton.visibility = View.GONE
                    showError("網路連線不穩定")
                }
            })
    }

    private fun updateCountyChips() {
        val counties = listOf("全部") + allItems.map { it.county }.distinct().sorted()
        chipGroup.removeAllViews()
        counties.forEach { county ->
            val chip = Chip(this, null, com.google.android.material.R.attr.chipStyle)
            chip.text = county
            chip.isCheckable = true
            chip.isChecked = county == selectedCounty
            chip.setOnCheckedChangeListener { btn: CompoundButton, isChecked: Boolean ->
                if (isChecked) {
                    selectedCounty = btn.text.toString()
                    applyFilter()
                }
            }
            chipGroup.addView(chip)
        }
    }

    private fun filteredItems(): List<WeatherObservation> {
        return if (selectedCounty == "全部") allItems
        else allItems.filter { it.county == selectedCounty }
    }

    private fun applyFilter() {
        val filtered = filteredItems()
        adapter.setItems(filtered)
        if (showingMap) addMapMarkers(filtered)
    }

    private fun addMapMarkers(stations: List<WeatherObservation>) {
        mapView.overlays.clear()
        for (s in stations) {
            val lat = s.latitude ?: continue
            val lng = s.longitude ?: continue
            if (lat == 0.0 && lng == 0.0) continue

            val marker = Marker(mapView)
            marker.position = GeoPoint(lat, lng)
            marker.title = s.stationName
            val temp = s.temperature?.let { "${"%.1f".format(it)}°C" } ?: "--"
            marker.snippet = "${s.county} | ${s.weatherSummary} | $temp"
            marker.setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM)
            marker.setOnMarkerClickListener { mk, _ ->
                mk.showInfoWindow()
                true
            }
            mapView.overlays.add(marker)
        }
        mapView.invalidate()
    }

    private fun showError(msg: String) {
        tvError.text = msg
        layoutError.visibility = View.VISIBLE
        rv.visibility = View.GONE
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
}

class WeatherAdapter : RecyclerView.Adapter<WeatherAdapter.ViewHolder>() {
    private var items: List<WeatherObservation> = emptyList()

    fun setItems(newItems: List<WeatherObservation>) {
        items = newItems
        notifyDataSetChanged()
    }

    inner class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val tvStationName: TextView = itemView.findViewById(R.id.tv_station_name)
        val tvCounty: TextView = itemView.findViewById(R.id.tv_county)
        val tvWeatherIcon: TextView = itemView.findViewById(R.id.tv_weather_icon)
        val tvTemperature: TextView = itemView.findViewById(R.id.tv_temperature)
        val tvHumidity: TextView = itemView.findViewById(R.id.tv_humidity)
        val tvRainfall: TextView = itemView.findViewById(R.id.tv_rainfall)
        val tvWindSpeed: TextView = itemView.findViewById(R.id.tv_wind_speed)
        val tvSunshine: TextView = itemView.findViewById(R.id.tv_sunshine)
        val tvObsTime: TextView = itemView.findViewById(R.id.tv_obs_time)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_weather_station, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val item = items[position]
        holder.tvStationName.text = item.stationName
        holder.tvCounty.text = item.county
        holder.tvWeatherIcon.text = weatherIcon(item.weatherSummary)
        holder.tvTemperature.text = item.temperature?.let { "${"%.1f".format(it)}°C" } ?: "--"
        holder.tvHumidity.text = item.relHumidity?.let { "${"%.0f".format(it)}%" } ?: "--"
        holder.tvRainfall.text = item.rainfall?.let { "${"%.1f".format(it)}mm" } ?: "--"
        holder.tvWindSpeed.text = item.windSpeed?.let { "${"%.1f".format(it)}m/s" } ?: "--"
        holder.tvSunshine.text = item.sunshineHours?.let { "${"%.1f".format(it)}h" } ?: "--"
        holder.tvObsTime.text = item.obsTime
    }

    private fun weatherIcon(summary: String): String = when {
        summary.contains("Rainy") || summary.contains("rainy") -> "🌧"
        summary.contains("Hot") || summary.contains("hot") -> "☀️"
        summary.contains("Warm") || summary.contains("warm") -> "🌤"
        summary.contains("Cool") || summary.contains("cool") -> "🌥"
        summary.contains("Cold") || summary.contains("cold") -> "🌨"
        else -> "🌡"
    }

    override fun getItemCount() = items.size
}
