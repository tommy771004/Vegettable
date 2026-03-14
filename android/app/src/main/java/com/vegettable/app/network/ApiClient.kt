package com.vegettable.app.network

import com.vegettable.app.BuildConfig
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit
import kotlin.concurrent.Volatile

/**
 * Retrofit 單例客戶端
 */
class ApiClient private constructor() {
    val api: ApiService

    init {
        val logging = HttpLoggingInterceptor()
        logging.setLevel(HttpLoggingInterceptor.Level.BODY)

        val client = OkHttpClient.Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(15, TimeUnit.SECONDS)
            .addInterceptor(logging)
            .build()

        val retrofit = Retrofit.Builder()
            .baseUrl(BuildConfig.API_BASE_URL)
            .client(client)
            .addConverterFactory(GsonConverterFactory.create())
            .build()

        this.api = retrofit.create<ApiService>(ApiService::class.java)
    }

    companion object {
        @JvmStatic
        @Volatile
        var instance: ApiClient? = null
            get() {
                if (field == null) {
                    synchronized(ApiClient::class.java) {
                        if (field == null) {
                            field = ApiClient()
                        }
                    }
                }
                return field
            }
            private set
    }
}
