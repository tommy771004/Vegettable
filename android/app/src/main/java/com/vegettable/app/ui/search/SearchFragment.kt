package com.vegettable.app.ui.search

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.text.Editable
import android.text.TextWatcher
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.textfield.TextInputEditText
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

class SearchFragment : Fragment(), ProductAdapter.OnItemClickListener {
    private var etSearch: TextInputEditText? = null
    private var rvResults: RecyclerView? = null
    private var tvResultCount: TextView? = null
    private var tvSearchError: TextView? = null
    private var tvEmptyResults: TextView? = null
    private var adapter: ProductAdapter? = null
    private var prefs: PrefsManager? = null
    private val handler = Handler(Looper.getMainLooper())
    private var searchRunnable: Runnable? = null

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_search, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        prefs = PrefsManager(requireContext())

        etSearch = view.findViewById(R.id.et_search)
        rvResults = view.findViewById(R.id.rv_results)
        tvResultCount = view.findViewById(R.id.tv_result_count)
        tvSearchError = view.findViewById(R.id.tv_search_error)
        tvEmptyResults = view.findViewById(R.id.tv_empty)

        rvResults?.layoutManager = LinearLayoutManager(requireContext())
        adapter = ProductAdapter(this, prefs?.favorites ?: mutableSetOf())
        adapter?.setPriceUnit(prefs?.priceUnit)
        rvResults?.adapter = adapter

        etSearch?.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable) {
                searchRunnable?.let { handler.removeCallbacks(it) }
                searchRunnable = Runnable { performSearch(s.toString().trim()) }
                handler.postDelayed(searchRunnable!!, 300)
            }
        })
    }

    private fun performSearch(keyword: String) {
        if (keyword.isEmpty()) {
            adapter?.setItems(mutableListOf())
            tvResultCount?.visibility = View.GONE
            tvSearchError?.visibility = View.GONE
            tvEmptyResults?.visibility = View.GONE
            return
        }

        tvSearchError?.visibility = View.GONE
        tvEmptyResults?.visibility = View.GONE

        instance?.api?.searchProducts(keyword)?.enqueue(object : Callback<ApiResponse<MutableList<ProductSummary?>?>?> {
            override fun onResponse(
                call: Call<ApiResponse<MutableList<ProductSummary?>?>?>,
                response: Response<ApiResponse<MutableList<ProductSummary?>?>?>
            ) {
                if (!isAdded) return

                if (response.isSuccessful && response.body()?.isSuccess == true && response.body()?.data != null) {
                    val results = response.body()?.data?.filterNotNull()?.toMutableList() ?: mutableListOf()

                    adapter?.setItems(results)

                    if (results.isEmpty()) {
                        tvEmptyResults?.visibility = View.VISIBLE
                        tvResultCount?.visibility = View.GONE
                    } else {
                        tvResultCount?.text = "找到 ${results.size} 項結果"
                        tvResultCount?.visibility = View.VISIBLE
                        tvEmptyResults?.visibility = View.GONE
                    }
                } else {
                    tvSearchError?.text = "搜尋失敗，請稍後再試"
                    tvSearchError?.visibility = View.VISIBLE
                }
            }

            override fun onFailure(call: Call<ApiResponse<MutableList<ProductSummary?>?>?>, t: Throwable) {
                if (!isAdded) return
                tvSearchError?.text = "搜尋失敗: ${t.message}"
                tvSearchError?.visibility = View.VISIBLE
            }
        })
    }

    override fun onItemClick(product: ProductSummary?) {
        product?.let {
            startActivity(Intent(requireContext(), DetailActivity::class.java).apply {
                putExtra("cropName", it.cropName)
                putExtra("cropCode", it.cropCode)
            })
        }
    }

    override fun onFavoriteClick(product: ProductSummary?) {
        product?.let {
            prefs?.toggleFavorite(it.cropCode)
            adapter?.setFavorites(prefs?.favorites ?: mutableSetOf())
            adapter?.notifyDataSetChanged()
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        searchRunnable?.let { handler.removeCallbacks(it) }
    }
}
