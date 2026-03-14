package com.vegettable.app.ui.seasonal

import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.CompoundButton
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout.OnRefreshListener
import com.google.android.material.chip.Chip
import com.google.android.material.chip.ChipGroup
import com.vegettable.app.R
import com.vegettable.app.model.ApiResponse
import com.vegettable.app.model.SeasonalInfo
import com.vegettable.app.network.ApiClient.Companion.instance
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import java.util.Calendar

class SeasonalActivity : AppCompatActivity() {
    private var rv: RecyclerView? = null
    private var swipeRefresh: SwipeRefreshLayout? = null
    private var chipGroup: ChipGroup? = null
    private var adapter: SeasonalAdapter? = null
    private var selectedCategory: String? = "vegetable"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_seasonal)

        findViewById<View?>(R.id.btn_back).setOnClickListener(View.OnClickListener { v: View? -> finish() })

        rv = findViewById<RecyclerView>(R.id.rv_seasonal)
        swipeRefresh = findViewById<SwipeRefreshLayout>(R.id.swipe_refresh)
        chipGroup = findViewById<ChipGroup>(R.id.chip_group_category)

        rv!!.setLayoutManager(LinearLayoutManager(this))
        adapter = SeasonalAdapter()
        rv!!.setAdapter(adapter)

        setupCategories()
        swipeRefresh!!.setOnRefreshListener(OnRefreshListener { this.loadData() })

        loadData()
    }

    private fun setupCategories() {
        val cats = arrayOf<Array<String?>?>(
            arrayOf<String?>("vegetable", "蔬菜"),
            arrayOf<String?>("fruit", "水果"),
            arrayOf<String?>("flower", "花卉")
        )
        for (c in cats) {
            val chip = Chip(this)
            chip.setText(c!![1])
            chip.setCheckable(true)
            chip.setTag(c[0])
            if (c[0] == selectedCategory) chip.setChecked(true)
            chip.setOnCheckedChangeListener(CompoundButton.OnCheckedChangeListener { v: CompoundButton?, checked: Boolean ->
                if (checked) {
                    selectedCategory = v!!.getTag() as String?
                    loadData()
                }
            })
            chipGroup!!.addView(chip)
        }
    }

    private fun loadData() {
        swipeRefresh!!.setRefreshing(true)
        instance!!.api.getSeasonalInfo(selectedCategory)!!
            .enqueue(object : Callback<ApiResponse<MutableList<SeasonalInfo?>?>?> {
                override fun onResponse(
                    call: Call<ApiResponse<MutableList<SeasonalInfo?>?>?>,
                    response: Response<ApiResponse<MutableList<SeasonalInfo?>?>?>
                ) {
                    swipeRefresh!!.setRefreshing(false)
                    if (response.isSuccessful() && response.body() != null) {
                        adapter!!.setItems(response.body()!!.data)
                    }
                }

                override fun onFailure(
                    call: Call<ApiResponse<MutableList<SeasonalInfo?>?>?>,
                    t: Throwable
                ) {
                    swipeRefresh!!.setRefreshing(false)
                }
            })
    }

    internal class SeasonalAdapter : RecyclerView.Adapter<SeasonalAdapter.VH?>() {
        private var items: MutableList<SeasonalInfo> = ArrayList<SeasonalInfo>()

        fun setItems(list: MutableList<SeasonalInfo?>?) {
            this.items = (if (list != null) list else ArrayList<SeasonalInfo>()) as MutableList<SeasonalInfo>
            notifyDataSetChanged()
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
            val v = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_seasonal, parent, false)
            return VH(v)
        }

        override fun onBindViewHolder(h: VH, pos: Int) {
            val info = items.get(pos)
            h.tvName.setText(info.cropName)
            h.tvNote.setText(info.seasonNote)

            // 當季 badge
            if (info.isInSeason) {
                h.tvBadge.setText("當季")
                h.tvBadge.setTextColor(Color.parseColor("#2E7D32"))
                val bg = GradientDrawable()
                bg.setColor(Color.parseColor("#1A4CAF50"))
                bg.setCornerRadius(20f)
                h.tvBadge.setBackground(bg)
            } else {
                h.tvBadge.setText("非當季")
                h.tvBadge.setTextColor(Color.parseColor("#757575"))
                val bg = GradientDrawable()
                bg.setColor(Color.parseColor("#10808080"))
                bg.setCornerRadius(20f)
                h.tvBadge.setBackground(bg)
            }

            // 12 月份
            h.layoutMonths.removeAllViews()
            val currentMonth = Calendar.getInstance().get(Calendar.MONTH) + 1
            val peaks = if (info.peakMonths != null) info.peakMonths else ArrayList<Int?>()

            for (m in 1..12) {
                val tv = TextView(h.itemView.getContext())
                tv.setText(m.toString())
                tv.setTextSize(10f)
                tv.setGravity(Gravity.CENTER)

                val params = LinearLayout.LayoutParams(0, 28, 1f)
                params.setMargins(1, 0, 1, 0)
                tv.setLayoutParams(params)

                val cellBg = GradientDrawable()
                cellBg.setCornerRadius(4f)
                if (peaks.contains(m)) {
                    cellBg.setColor(Color.parseColor("#4CAF50"))
                    tv.setTextColor(Color.WHITE)
                } else if (m == currentMonth) {
                    cellBg.setColor(Color.parseColor("#E8F5E9"))
                    tv.setTextColor(Color.parseColor("#2E7D32"))
                } else {
                    cellBg.setColor(Color.parseColor("#F5F5F5"))
                    tv.setTextColor(Color.parseColor("#9E9E9E"))
                }
                tv.setBackground(cellBg)
                h.layoutMonths.addView(tv)
            }
        }

        override fun getItemCount(): Int {
            return items.size
        }

        internal class VH(v: View) : RecyclerView.ViewHolder(v) {
            var tvName: TextView
            var tvBadge: TextView
            var tvNote: TextView
            var layoutMonths: LinearLayout

            init {
                tvName = v.findViewById<TextView>(R.id.tv_crop_name)
                tvBadge = v.findViewById<TextView>(R.id.tv_season_badge)
                tvNote = v.findViewById<TextView>(R.id.tv_note)
                layoutMonths = v.findViewById<LinearLayout>(R.id.layout_months)
            }
        }
    }
}
