package com.vegettable.app;

import android.os.Bundle;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;

import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.vegettable.app.ui.home.HomeFragment;
import com.vegettable.app.ui.search.SearchFragment;
import com.vegettable.app.ui.favorites.FavoritesFragment;
import com.vegettable.app.ui.settings.SettingsFragment;
import com.vegettable.app.util.PermissionManager;

public class MainActivity extends AppCompatActivity {

    private ActivityResultLauncher<String[]> locationLauncher;
    private ActivityResultLauncher<String> notificationLauncher;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // 註冊權限請求 Launcher
        locationLauncher = registerForActivityResult(
                new ActivityResultContracts.RequestMultiplePermissions(),
                results -> {
                    // 權限請求完成 (無論成功或失敗，應用都能繼續運行)
                }
        );

        notificationLauncher = registerForActivityResult(
                new ActivityResultContracts.RequestPermission(),
                isGranted -> {
                    // 權限請求完成
                }
        );

        // 請求權限 (如果尚未授予)
        if (!PermissionManager.hasLocationPermission(this)) {
            PermissionManager.requestLocationPermission(this, locationLauncher);
        }

        if (!PermissionManager.hasNotificationPermission(this)) {
            PermissionManager.requestNotificationPermission(this, notificationLauncher);
        }

        BottomNavigationView bottomNav = findViewById(R.id.bottom_nav);

        // 預設載入首頁
        if (savedInstanceState == null) {
            loadFragment(new HomeFragment());
        }

        bottomNav.setOnItemSelectedListener(item -> {
            Fragment fragment;
            int id = item.getItemId();

            if (id == R.id.nav_home) {
                fragment = new HomeFragment();
            } else if (id == R.id.nav_search) {
                fragment = new SearchFragment();
            } else if (id == R.id.nav_favorites) {
                fragment = new FavoritesFragment();
            } else if (id == R.id.nav_settings) {
                fragment = new SettingsFragment();
            } else {
                return false;
            }

            loadFragment(fragment);
            return true;
        });
    }

    private void loadFragment(Fragment fragment) {
        getSupportFragmentManager()
                .beginTransaction()
                .replace(R.id.fragment_container, fragment)
                .commit();
    }
}
