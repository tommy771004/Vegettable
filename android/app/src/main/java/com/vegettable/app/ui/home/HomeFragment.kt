package com.vegettable.app.ui.home

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.CompoundButton
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout.OnRefreshListener
import com.google.android.material.chip.Chip
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.vegettable.app.R
import com.vegettable.app.databinding.FragmentHomeBinding
import com.vegettable.app.model.ApiResponse
import com.vegettable.app.model.ProductSummary
import com.vegettable.app.network.ApiClient.Companion.instance
import com.vegettable.app.ui.adapter.ProductAdapter
import com.vegettable.app.ui.adapter.SkeletonAdapter
import com.vegettable.app.ui.detail.DetailActivity
import com.vegettable.app.util.PrefsManager
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response

class HomeFragment : Fragment(), ProductAdapter.OnItemClickListener {
    private var binding: FragmentHomeBinding? = null
    private var adapter: ProductAdapter? = null
    private var prefs: PrefsManager? = null
    private var selectedCategory: String? = null

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        binding = FragmentHomeBinding.inflate(inflater, container, false)
        return binding!!.getRoot()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        prefs = PrefsManager(requireContext())

        setupRecyclerView()
        setupCategoryChips()
        setupListeners()

        loadProducts()
    }

    private fun setupRecyclerView() {
        binding!!.rvProducts.setLayoutManager(LinearLayoutManager(requireContext()))
        adapter = ProductAdapter(this, prefs!!.favorites)
        adapter!!.setPriceUnit(prefs!!.priceUnit)
        adapter!!.setShowRetail(prefs!!.isShowRetailPrice)
        binding!!.rvProducts.setAdapter(adapter)

        // 骨架屏
        binding!!.rvSkeleton.setLayoutManager(LinearLayoutManager(requireContext()))
        binding!!.rvSkeleton.setAdapter(SkeletonAdapter(8))
    }

    private fun setupListeners() {
        // 下拉刷新配色與事件
        binding!!.swipeRefresh.setColorSchemeResources(R.color.primary)
        binding!!.swipeRefresh.setOnRefreshListener(OnRefreshListener { this.loadProducts() })

        // 重試按鈕
        binding!!.btnRetry.setOnClickListener(View.OnClickListener { v: View? -> loadProducts() })
    }

    private fun setupCategoryChips() {
        binding!!.chipGroupCategory.removeAllViews()
        for (cat in CATEGORIES) {
            // 使用 ContextThemeWrapper 或指定 Style
            val chip = Chip(requireContext(), null, com.google.android.material.R.attr.chipStyle)
            chip.setText(cat!![1])
            chip.setCheckable(true)
            chip.setTag(cat[0])

            // 套用你的 Liquid Glass 膠囊樣式
            // 注意：如果 XML 中定義了 CategoryChip style，建議在布局中動態引用
            if ("all" == cat[0]) {
                chip.setChecked(true)
            }

            chip.setOnCheckedChangeListener(CompoundButton.OnCheckedChangeListener { buttonView: CompoundButton?, isChecked: Boolean ->
                if (isChecked) {
                    val tag = buttonView!!.getTag() as String?
                    selectedCategory = if ("all" == tag) null else tag
                    loadProducts()
                }
            })
            binding!!.chipGroupCategory.addView(chip)
        }
    }

    private fun loadProducts() {
        // 如果不是下拉刷新觸發的，顯示骨架屏
        if (!binding!!.swipeRefresh.isRefreshing()) {
            binding!!.rvSkeleton.setVisibility(View.VISIBLE)
            binding!!.rvProducts.setVisibility(View.GONE)
        }
        binding!!.layoutError.setVisibility(View.GONE)

        instance!!.api.getProducts(selectedCategory)!!
            .enqueue(object : Callback<ApiResponse<MutableList<ProductSummary?>?>?> {
                override fun onResponse(
                    call: Call<ApiResponse<MutableList<ProductSummary?>?>?>,
                    response: Response<ApiResponse<MutableList<ProductSummary?>?>?>
                ) {
                    if (!isAdded()) return

                    binding!!.swipeRefresh.setRefreshing(false)
                    binding!!.rvSkeleton.setVisibility(View.GONE)

                    if (response.isSuccessful() && response.body() != null && response.body()!!.isSuccess && response.body()!!.data != null) {
                        val products: MutableList<ProductSummary> = response.body()!!.data!!.filterNotNull().toMutableList()
                        adapter!!.setItems(products)
                        binding!!.rvProducts.setVisibility(View.VISIBLE)
                        binding!!.tvOfflineBanner.visibility = View.GONE

                        // 快取最新的產品列表
                        prefs!!.cacheProducts(Gson().toJson(products))
                    } else {
                        val errorMsg = when (response.code()) {
                            400 -> "請求格式錯誤"
                            404 -> "查無資料"
                            429 -> "請求過於頻繁，請稍後再試"
                            in 500..599 -> "伺服器發生錯誤，請稍後再試"
                            else -> "無法取得最新資料"
                        }
                        handleLoadError(errorMsg)
                    }
                }

                override fun onFailure(
                    call: Call<ApiResponse<MutableList<ProductSummary?>?>?>,
                    t: Throwable
                ) {
                    if (!isAdded()) return

                    binding!!.swipeRefresh.setRefreshing(false)
                    binding!!.rvSkeleton.setVisibility(View.GONE)
                    handleLoadError("網路連線不穩定")
                }
            })
    }

    private fun handleLoadError(message: String?) {
        // 嘗試從快取讀取
        val cached = prefs!!.cachedProducts
        if (cached != null) {
            try {
                val products = Gson().fromJson<MutableList<ProductSummary>>(
                    cached,
                    object : TypeToken<MutableList<ProductSummary>>() {}.getType()
                )
                if (products != null && !products.isEmpty()) {
                    adapter!!.setItems(products)
                    binding!!.rvProducts.setVisibility(View.VISIBLE)
                    val ageText = prefs!!.cacheAgeText
                    binding!!.tvOfflineBanner.text = "⚠️ 離線模式｜顯示 $ageText 的快取資料"
                    binding!!.tvOfflineBanner.visibility = View.VISIBLE
                    return
                }
            } catch (ignored: Exception) {
            }
        }

        // 若連快取都沒有，則顯示錯誤畫面
        binding!!.tvError.setText(message)
        binding!!.layoutError.setVisibility(View.VISIBLE)
        binding!!.rvProducts.setVisibility(View.GONE)
    }

    override fun onItemClick(product: ProductSummary?) {
        product?.let {
            val intent = Intent(requireContext(), DetailActivity::class.java)
            intent.putExtra("cropName", it.cropName)
            intent.putExtra("cropCode", it.cropCode)
            startActivity(intent)
        }
    }

    override fun onFavoriteClick(product: ProductSummary?) {
        product?.let {
            prefs!!.toggleFavorite(it.cropCode)
            // 更新 Adapter 中的收藏狀態
            adapter!!.setFavorites(prefs!!.favorites)
            adapter!!.notifyDataSetChanged()
        }
    }

    override fun onResume() {
        super.onResume()
        // 當從 DetailActivity 返回時，確保收藏狀態與單位設定同步更新
        if (adapter != null) {
            adapter!!.setPriceUnit(prefs!!.priceUnit)
            adapter!!.setShowRetail(prefs!!.isShowRetailPrice)
            adapter!!.setFavorites(prefs!!.favorites) // 關鍵：同步收藏狀態
            adapter!!.notifyDataSetChanged()
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        binding = null // 避免 Memory Leak
    }

    companion object {
        private val CATEGORIES = arrayOf<Array<String?>?>(
            arrayOf<String?>("all", "全部"),
            arrayOf<String?>("vegetable", "蔬菜"),
            arrayOf<String?>("fruit", "水果"),
            arrayOf<String?>("fish", "漁產"),
            arrayOf<String?>("poultry", "肉品"),
            arrayOf<String?>("flower", "花卉"),
            arrayOf<String?>("rice", "白米")
        )
    }
}
