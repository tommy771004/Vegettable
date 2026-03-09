package com.vegettable.app.util;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkRequest;

import androidx.annotation.NonNull;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

/**
 * 網路狀態監控 — 使用 ConnectivityManager 偵測離線/上線狀態
 */
public class NetworkMonitor {

    private static volatile NetworkMonitor instance;
    private final ConnectivityManager connectivityManager;
    private final MutableLiveData<Boolean> isConnected = new MutableLiveData<>(true);

    private NetworkMonitor(Context context) {
        connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        registerCallback();
    }

    public static NetworkMonitor getInstance(Context context) {
        if (instance == null) {
            synchronized (NetworkMonitor.class) {
                if (instance == null) {
                    instance = new NetworkMonitor(context.getApplicationContext());
                }
            }
        }
        return instance;
    }

    public LiveData<Boolean> getIsConnected() {
        return isConnected;
    }

    public boolean isOnline() {
        Boolean value = isConnected.getValue();
        return value != null && value;
    }

    private void registerCallback() {
        NetworkRequest request = new NetworkRequest.Builder()
                .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                .build();

        connectivityManager.registerNetworkCallback(request, new ConnectivityManager.NetworkCallback() {
            @Override
            public void onAvailable(@NonNull Network network) {
                isConnected.postValue(true);
            }

            @Override
            public void onLost(@NonNull Network network) {
                isConnected.postValue(false);
            }

            @Override
            public void onUnavailable() {
                isConnected.postValue(false);
            }
        });
    }
}
