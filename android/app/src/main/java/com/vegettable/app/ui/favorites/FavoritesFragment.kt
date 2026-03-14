package com.vegettable.app.ui.favorites

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.vegettable.app.R
import com.vegettable.app.model.ApiResponse
import com.vegettable.app.model.ProductSummary
import com.vegettable.app.network.ApiClient.Companion.instance
import com.vegettable.app.ui.adapter.ProductAdapter
import com.vegettable.app.ui.detail.DetailActivity
import com.vegettable.app.util.PrefsManager
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response

class FavoritesFragment : Fragment(), ProductAdapter.OnItemClickListener {
    private var rvFavorites: RecyclerView? = null
    private var tvEmpty: TextView? = null
    private var tvFavCount: TextView? = null
    private var adapter: ProductAdapter? = null
    private var prefs: PrefsManager? = null

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_favorites, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        prefs = PrefsManager(requireContext())

        rvFavorites = view.findViewById<RecyclerView>(R.id.rv_favorites)
        tvEmpty = view.findViewById<TextView>(R.id.tv_empty)
        tvFavCount = view.findViewById<TextView>(R.id.tv_fav_count)

        rvFavorites!!.setLayoutManager(LinearLayoutManager(requireContext()))
        adapter = ProductAdapter(this, prefs!!.favorites)
        adapter!!.setPriceUnit(prefs!!.priceUnit)
        rvFavorites!!.setAdapter(adapter)

        loadFavorites()
    }

    override fun onResume() {
        super.onResume()
        loadFavorites()
    }

    private fun loadFavorites() {
        val favCodes = prefs!!.favorites

        if (favCodes.isEmpty()) {
            tvEmpty!!.setVisibility(View.VISIBLE)
            rvFavorites!!.setVisibility(View.GONE)
            tvFavCount!!.setText("0 項收藏")
            return
        }

        tvFavCount!!.setText(favCodes.size.toString() + " 項收藏")

        // 從快取中過濾收藏項目
        val cached = prefs!!.cachedProducts
        if (cached != null) {
            try {
                val all = Gson().fromJson<MutableList<ProductSummary?>>(
                    cached,
                    object : TypeToken<MutableList<ProductSummary?>?>() {}.getType()
                )
                val favProducts: MutableList<ProductSummary> = ArrayList<ProductSummary>()
                if (all != null) {
                    for (p in all) {
                        if (p != null && favCodes.contains(p.cropCode)) {
                            favProducts.add(p)
                        }
                    }
                }
                if (!favProducts.isEmpty()) {
                    adapter!!.setItems(favProducts)
                    rvFavorites!!.setVisibility(View.VISIBLE)
                    tvEmpty!!.setVisibility(View.GONE)
                    return
                }
            } catch (ignored: Exception) {
            }
        }

        // 若快取為空，從 API 載入全部產品再過濾
        instance!!.api.getProducts(null)!!
            .enqueue(object : Callback<ApiResponse<MutableList<ProductSummary?>?>?> {
                override fun onResponse(
                    call: Call<ApiResponse<MutableList<ProductSummary?>?>?>,
                    response: Response<ApiResponse<MutableList<ProductSummary?>?>?>
                ) {
                    if (!isAdded()) return
                    if (response.isSuccessful() && response.body() != null && response.body()!!.isSuccess && response.body()!!.data != null) {
                        val favProducts: MutableList<ProductSummary> = ArrayList<ProductSummary>()
                        for (p in response.body()!!.data!!) {
                            if (p != null && favCodes.contains(p.cropCode)) {
                                favProducts.add(p)
                            }
                        }
                        adapter!!.setItems(favProducts)
                        rvFavorites!!.setVisibility(if (favProducts.isEmpty()) View.GONE else View.VISIBLE)
                        tvEmpty!!.setVisibility(if (favProducts.isEmpty()) View.VISIBLE else View.GONE)
                    }
                }

                override fun onFailure(
                    call: Call<ApiResponse<MutableList<ProductSummary?>?>?>,
                    t: Throwable
                ) {
                    if (!isAdded()) return
                    tvEmpty!!.setVisibility(View.VISIBLE)
                }
            })
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
            loadFavorites()
        }
    }
}
