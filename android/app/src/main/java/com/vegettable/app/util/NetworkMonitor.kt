package com.vegettable.app.util

import android.content.Context
import android.net.ConnectivityManager
import android.net.ConnectivityManager.NetworkCallback
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData

class NetworkMonitor private constructor(context: Context) {
    private val connectivityManager: ConnectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private val isConnected = MutableLiveData<Boolean>(true)

    init {
        registerCallback()
    }

    fun getIsConnected(): LiveData<Boolean> = isConnected

    val isOnline: Boolean
        get() = isConnected.value ?: false

    private fun registerCallback() {
        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()

        connectivityManager.registerNetworkCallback(request, object : NetworkCallback() {
            override fun onAvailable(network: Network) {
                isConnected.postValue(true)
            }

            override fun onLost(network: Network) {
                isConnected.postValue(false)
            }

            override fun onUnavailable() {
                isConnected.postValue(false)
            }
        })
    }

    companion object {
        @Volatile
        private var INSTANCE: NetworkMonitor? = null

        fun getInstance(context: Context): NetworkMonitor =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: NetworkMonitor(context.applicationContext).also { INSTANCE = it }
            }
    }
}