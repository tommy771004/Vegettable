package com.vegettable.app.ui.detail

import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.RadioGroup
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.vegettable.app.R
import com.vegettable.app.databinding.ActivityDetailBinding
import com.vegettable.app.model.ApiResponse
import com.vegettable.app.model.CreateAlertRequest
import com.vegettable.app.model.DailyPrice
import com.vegettable.app.model.MonthlyPrice
import com.vegettable.app.model.PriceAlert
import com.vegettable.app.model.PricePrediction
import com.vegettable.app.model.ProductDetail
import com.vegettable.app.model.Recipe
import com.vegettable.app.network.ApiClient.Companion.instance
import com.vegettable.app.util.PrefsManager
import com.vegettable.app.util.PriceUtils
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import kotlin.math.max

class DetailActivity : AppCompatActivity() {
    private var binding: ActivityDetailBinding? = null
    private var cropName: String? = null
    private var cropCode: String? = null
    private var prefs: PrefsManager? = null
    private var currentAvgPrice: Double = 0.0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityDetailBinding.inflate(layoutInflater)
        setContentView(binding!!.root)

        prefs = PrefsManager(this)
        cropName = intent.getStringExtra("cropName")
        cropCode = intent.getStringExtra("cropCode")

        if (cropName == null) {
            Toast.makeText(this, "參數錯誤", Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        setupUI()
        loadProductDetail()
        loadPrediction()
        loadRecipes()
    }

    private fun setupUI() {
        binding!!.tvTitle.text = cropName
        binding!!.btnBack.setOnClickListener { finish() }

        updateFavoriteIcon()
        binding!!.btnFavorite.setOnClickListener {
            if (cropCode != null) {
                prefs!!.toggleFavorite(cropCode!!)
                updateFavoriteIcon()
            }
        }

        binding!!.btnShare.setOnClickListener {
            val priceText = binding!!.tvPrice.text
            val unit = if (prefs!!.priceUnit == "catty") "元/台斤" else "元/公斤"
            val shareText = "【$cropName】目前批發均價 $priceText $unit — 蔬果行情 App"
            val intent = Intent(Intent.ACTION_SEND)
            intent.type = "text/plain"
            intent.putExtra(Intent.EXTRA_TEXT, shareText)
            startActivity(Intent.createChooser(intent, "分享價格資訊"))
        }

        binding!!.btnAlert.setOnClickListener {
            showAlertDialog()
        }
    }

    private fun updateFavoriteIcon() {
        val isFav = cropCode != null && prefs!!.isFavorite(cropCode!!)
        binding!!.btnFavorite.setImageResource(
            if (isFav) R.drawable.ic_favorite_on else R.drawable.ic_favorite_off
        )
        binding!!.btnFavorite.contentDescription = if (isFav) "取消收藏" else "加入收藏"
    }

    private fun loadProductDetail() {
        binding!!.progressDetail.visibility = View.VISIBLE

        instance!!.api.getProductDetail(cropName)!!
            .enqueue(object : Callback<ApiResponse<ProductDetail?>?> {
                override fun onResponse(
                    call: Call<ApiResponse<ProductDetail?>?>,
                    response: Response<ApiResponse<ProductDetail?>?>
                ) {
                    binding!!.progressDetail.visibility = View.GONE

                    if (response.isSuccessful && response.body() != null && response.body()!!.isSuccess && response.body()!!.data != null) {
                        displayDetail(response.body()!!.data!!)
                    } else {
                        Toast.makeText(this@DetailActivity, "載入失敗", Toast.LENGTH_SHORT).show()
                    }
                }

                override fun onFailure(call: Call<ApiResponse<ProductDetail?>?>, t: Throwable) {
                    binding!!.progressDetail.visibility = View.GONE
                    Toast.makeText(this@DetailActivity, "網路連線異常", Toast.LENGTH_SHORT).show()
                }
            })
    }

    private fun displayDetail(detail: ProductDetail) {
        if (detail.aliases != null && detail.aliases.isNotEmpty()) {
            binding!!.tvAliases.text = "又稱：" + detail.aliases.filterNotNull().joinToString("、")
            binding!!.tvAliases.visibility = View.VISIBLE
        } else {
            binding!!.tvAliases.visibility = View.GONE
        }

        currentAvgPrice = detail.avgPrice
        var price = detail.avgPrice
        val unit = prefs!!.priceUnit
        if ("catty" == unit) {
            price = PriceUtils.convertToCatty(price)
        }
        binding!!.tvPrice.text = PriceUtils.formatPrice(price)
        binding!!.tvPrice.setTextColor(PriceUtils.getPriceLevelColor(detail.priceLevel))
        binding!!.tvPriceUnit.text = if ("catty" == unit) "元/台斤 (批發均價)" else "元/公斤 (批發均價)"

        binding!!.tvTrendArrow.text = PriceUtils.getTrendArrow(detail.trend)
        binding!!.tvTrendArrow.setTextColor(PriceUtils.getTrendColor(detail.trend))

        binding!!.tvLevelBadge.text = PriceUtils.getPriceLevelLabel(detail.priceLevel)
        binding!!.tvLevelBadge.setTextColor(PriceUtils.getPriceLevelColor(detail.priceLevel))
        val badgeBg = GradientDrawable()
        badgeBg.setColor(PriceUtils.getPriceLevelBgColor(detail.priceLevel))
        badgeBg.cornerRadius = dpToPx(12).toFloat()
        binding!!.tvLevelBadge.background = badgeBg

        var histPrice = detail.historicalAvgPrice
        if ("catty" == unit) histPrice = PriceUtils.convertToCatty(histPrice)
        binding!!.tvHistorical.text = PriceUtils.formatPrice(histPrice) + " 元"

        if (detail.dailyPrices != null && detail.dailyPrices.isNotEmpty()) {
            val vol = detail.dailyPrices.last()!!.volume
            binding!!.tvVolume.text = PriceUtils.formatPrice(vol) + " kg"
        }

        displaySimpleChart(binding!!.chartDailyContainer, detail.dailyPrices, "#43A047")
        displaySimpleMonthlyChart(binding!!.chartMonthlyContainer, detail.monthlyPrices, "#2196F3")
    }

    private fun displaySimpleChart(
        container: LinearLayout,
        prices: MutableList<DailyPrice?>?,
        barColor: String
    ) {
        container.removeAllViews()
        if (prices == null || prices.isEmpty()) return

        var maxPrice = 0.0
        for (dp in prices) {
            if (dp != null) maxPrice = max(maxPrice, dp.avgPrice)
        }

        for (dp in prices) {
            if (dp != null) {
                container.addView(createChartRow(dp.date, dp.avgPrice, maxPrice, barColor))
            }
        }
    }

    private fun displaySimpleMonthlyChart(
        container: LinearLayout,
        prices: MutableList<MonthlyPrice?>?,
        barColor: String
    ) {
        container.removeAllViews()
        if (prices == null || prices.isEmpty()) return

        var maxPrice = 0.0
        for (mp in prices) {
            if (mp != null) maxPrice = max(maxPrice, mp.avgPrice)
        }

        for (mp in prices) {
            if (mp != null) {
                container.addView(createChartRow(mp.month, mp.avgPrice, maxPrice, barColor))
            }
        }
    }

    private fun createChartRow(
        label: String?,
        value: Double,
        maxValue: Double,
        barColor: String
    ): View {
        val row = LinearLayout(this)
        row.orientation = LinearLayout.HORIZONTAL
        row.setPadding(0, dpToPx(6), 0, dpToPx(6))
        row.gravity = Gravity.CENTER_VERTICAL

        val tvLabel = TextView(this)
        tvLabel.text = label
        tvLabel.textSize = 11f
        tvLabel.setTextColor(Color.parseColor("#8899A6"))
        tvLabel.layoutParams = LinearLayout.LayoutParams(dpToPx(75), -2)

        val bar = View(this)
        val maxWidth = dpToPx(160)
        var barWidth = if (maxValue > 0) (value / maxValue * maxWidth).toInt() else 0
        barWidth = max(barWidth, dpToPx(4))

        val barParams = LinearLayout.LayoutParams(barWidth, dpToPx(12))
        barParams.marginStart = dpToPx(8)
        bar.layoutParams = barParams

        val barBg = GradientDrawable()
        barBg.setColor(Color.parseColor(barColor))
        barBg.cornerRadius = dpToPx(6).toFloat()
        bar.background = barBg

        val tvVal = TextView(this)
        tvVal.text = " " + PriceUtils.formatPrice(value)
        tvVal.textSize = 11f
        tvVal.setTextColor(Color.parseColor("#0F1419"))

        row.addView(tvLabel)
        row.addView(bar)
        row.addView(tvVal)
        return row
    }

    private fun loadPrediction() {
        instance!!.api.getPrediction(cropName)!!
            .enqueue(object : Callback<ApiResponse<PricePrediction?>?> {
                override fun onResponse(
                    call: Call<ApiResponse<PricePrediction?>?>,
                    response: Response<ApiResponse<PricePrediction?>?>
                ) {
                    if (response.isSuccessful && response.body() != null && response.body()!!.data != null) {
                        val pred: PricePrediction = response.body()!!.data!!
                        binding!!.cardPrediction.visibility = View.VISIBLE

                        val arrow = PriceUtils.getTrendArrow(pred.direction)
                        val content = String.format(
                            "未來預測: %s 元 %s (%.1f%%)\n信心度: %.0f%%\n解析: %s",
                            PriceUtils.formatPrice(pred.predictedPrice), arrow,
                            pred.changePercent, pred.confidence, pred.reasoning
                        )
                        binding!!.tvPrediction.text = content
                        binding!!.progressConfidence.progress = pred.confidence.toInt()
                    }
                }

                override fun onFailure(call: Call<ApiResponse<PricePrediction?>?>, t: Throwable) {}
            })
    }

    private fun loadRecipes() {
        instance!!.api.getRecipes(cropName)!!
            .enqueue(object : Callback<ApiResponse<MutableList<Recipe?>?>?> {
                override fun onResponse(
                    call: Call<ApiResponse<MutableList<Recipe?>?>?>,
                    response: Response<ApiResponse<MutableList<Recipe?>?>?>
                ) {
                    if (response.isSuccessful && response.body() != null && response.body()!!.data != null) {
                        val recipes: MutableList<Recipe?> = response.body()!!.data!!
                        if (recipes.isNotEmpty()) {
                            binding!!.cardRecipes.visibility = View.VISIBLE
                            displayRecipes(recipes)
                        }
                    }
                }

                override fun onFailure(
                    call: Call<ApiResponse<MutableList<Recipe?>?>?>,
                    t: Throwable
                ) {
                }
            })
    }

    private fun displayRecipes(recipes: MutableList<Recipe?>) {
        binding!!.layoutRecipes.removeAllViews()
        for (r in recipes) {
            if (r == null) continue
            val item = LinearLayout(this)
            item.orientation = LinearLayout.VERTICAL
            item.setPadding(0, dpToPx(10), 0, dpToPx(10))

            val tvName = TextView(this)
            tvName.text = r.name + " (" + r.cookTimeMinutes + "分)"
            tvName.textSize = 15f
            tvName.setTypeface(null, Typeface.BOLD)
            tvName.setTextColor(Color.parseColor("#0F1419"))

            val tvDesc = TextView(this)
            tvDesc.text = r.description
            tvDesc.textSize = 13f
            tvDesc.setTextColor(Color.parseColor("#536471"))
            tvDesc.setPadding(0, dpToPx(4), 0, 0)

            item.addView(tvName)
            item.addView(tvDesc)
            binding!!.layoutRecipes.addView(item)
        }
    }

    // ─── 價格警示 Dialog ─────────────────────────────────────

    private fun showAlertDialog() {
        val dialogLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val pad = dpToPx(20)
            setPadding(pad, pad, pad, pad)
        }

        // 目前價格提示
        val tvCurrent = TextView(this).apply {
            text = "目前均價：${PriceUtils.formatPrice(currentAvgPrice)} 元/公斤"
            textSize = 13f
            setTextColor(Color.parseColor("#536471"))
        }
        dialogLayout.addView(tvCurrent)

        // 條件說明
        val tvCondLabel = TextView(this).apply {
            text = "通知條件"
            textSize = 14f
            setTextColor(Color.parseColor("#0F1419"))
            setPadding(0, dpToPx(12), 0, dpToPx(4))
        }
        dialogLayout.addView(tvCondLabel)

        // RadioGroup 選擇條件
        val radioGroup = RadioGroup(this).apply {
            orientation = RadioGroup.HORIZONTAL
        }
        val rbBelow = android.widget.RadioButton(this).apply {
            text = "低於目標"
            id = View.generateViewId()
            isChecked = true
        }
        val rbAbove = android.widget.RadioButton(this).apply {
            text = "高於目標"
            id = View.generateViewId()
        }
        radioGroup.addView(rbBelow)
        radioGroup.addView(rbAbove)
        dialogLayout.addView(radioGroup)

        // 目標價格輸入
        val tvPriceLabel = TextView(this).apply {
            text = "目標價格（元/公斤）"
            textSize = 14f
            setTextColor(Color.parseColor("#0F1419"))
            setPadding(0, dpToPx(12), 0, dpToPx(4))
        }
        dialogLayout.addView(tvPriceLabel)

        val etPrice = EditText(this).apply {
            hint = "例: 30.0"
            inputType = android.text.InputType.TYPE_CLASS_NUMBER or android.text.InputType.TYPE_NUMBER_FLAG_DECIMAL
        }
        dialogLayout.addView(etPrice)

        AlertDialog.Builder(this)
            .setTitle("設定價格警示 — $cropName")
            .setView(dialogLayout)
            .setPositiveButton("建立警示") { _, _ ->
                val priceText = etPrice.text.toString().trim()
                if (priceText.length > 10) {
                    Toast.makeText(this, "請輸入有效的目標價格", Toast.LENGTH_SHORT).show()
                    return@setPositiveButton
                }
                val targetPrice = priceText.toDoubleOrNull()
                if (targetPrice == null || targetPrice <= 0 || targetPrice > 99999) {
                    Toast.makeText(this, "請輸入 1 ~ 99,999 之間的有效價格", Toast.LENGTH_SHORT).show()
                    return@setPositiveButton
                }
                val condition = if (radioGroup.checkedRadioButtonId == rbBelow.id) "below" else "above"
                createPriceAlert(targetPrice, condition)
            }
            .setNegativeButton("取消", null)
            .show()
    }

    private fun createPriceAlert(targetPrice: Double, condition: String) {
        val deviceToken = prefs!!.getDeviceToken()
        val request = CreateAlertRequest(
            deviceToken = deviceToken,
            cropName = cropName ?: return,
            targetPrice = targetPrice,
            condition = condition
        )

        instance!!.api.createAlert(request)
            ?.enqueue(object : Callback<ApiResponse<PriceAlert?>?> {
                override fun onResponse(
                    call: Call<ApiResponse<PriceAlert?>?>,
                    response: Response<ApiResponse<PriceAlert?>?>
                ) {
                    if (response.isSuccessful && response.body()?.isSuccess == true) {
                        val condText = if (condition == "below") "低於" else "高於"
                        Toast.makeText(
                            this@DetailActivity,
                            "警示已建立！價格${condText} ${PriceUtils.formatPrice(targetPrice)} 元時將通知您",
                            Toast.LENGTH_LONG
                        ).show()
                    } else {
                        Toast.makeText(this@DetailActivity, "建立警示失敗，請稍後重試", Toast.LENGTH_SHORT).show()
                    }
                }

                override fun onFailure(call: Call<ApiResponse<PriceAlert?>?>, t: Throwable) {
                    Toast.makeText(this@DetailActivity, "網路連線異常，請稍後重試", Toast.LENGTH_SHORT).show()
                }
            })
    }

    private fun dpToPx(dp: Int): Int {
        val density = resources.displayMetrics.density
        return Math.round(dp.toFloat() * density)
    }

    override fun onDestroy() {
        super.onDestroy()
        binding = null
    }
}
