package com.vegettable.app.network;

import com.vegettable.app.BuildConfig;

import okhttp3.Interceptor;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

/**
 * Retrofit 單例客戶端（含指數退避重試）
 */
public class ApiClient {

    private static volatile ApiClient instance;
    private final ApiService apiService;

    private static final int MAX_RETRIES = 3;

    private ApiClient() {
        HttpLoggingInterceptor logging = new HttpLoggingInterceptor();
        logging.setLevel(BuildConfig.DEBUG
                ? HttpLoggingInterceptor.Level.BODY
                : HttpLoggingInterceptor.Level.NONE);

        // 指數退避重試攔截器（修正 response 洩漏問題）
        Interceptor retryInterceptor = chain -> {
            Request request = chain.request();
            Response response = null;
            IOException lastException = null;

            for (int attempt = 0; attempt <= MAX_RETRIES; attempt++) {
                try {
                    // 在重試前關閉上一次的 response body，避免連線洩漏
                    if (response != null) {
                        response.close();
                        response = null;
                    }
                    response = chain.proceed(request);
                    if (response.isSuccessful()) return response;
                    // 4xx 不重試（用戶端錯誤，重試無意義）
                    if (response.code() >= 400 && response.code() < 500) return response;
                    // 5xx 會重試，先關閉此次 response
                } catch (IOException e) {
                    lastException = e;
                }
                if (attempt < MAX_RETRIES) {
                    try {
                        long delay = (long) (1000 * Math.pow(2, attempt));
                        Thread.sleep(delay);
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                        if (response != null) response.close();
                        throw new IOException("重試被中斷", e);
                    }
                }
            }
            if (response != null) return response;
            throw lastException != null ? lastException : new IOException("重試失敗");
        };

        OkHttpClient client = new OkHttpClient.Builder()
                .connectTimeout(15, TimeUnit.SECONDS)
                .readTimeout(30, TimeUnit.SECONDS)
                .writeTimeout(15, TimeUnit.SECONDS)
                .addInterceptor(retryInterceptor)
                .addInterceptor(logging)
                .build();

        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl(BuildConfig.API_BASE_URL)
                .client(client)
                .addConverterFactory(GsonConverterFactory.create())
                .build();

        apiService = retrofit.create(ApiService.class);
    }

    public static ApiClient getInstance() {
        if (instance == null) {
            synchronized (ApiClient.class) {
                if (instance == null) {
                    instance = new ApiClient();
                }
            }
        }
        return instance;
    }

    public ApiService getApi() {
        return apiService;
    }
}
