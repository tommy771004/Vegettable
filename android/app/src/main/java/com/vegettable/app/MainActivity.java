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

    private HomeFragment homeFragment;
    private SearchFragment searchFragment;
    private FavoritesFragment favoritesFragment;
    private SettingsFragment settingsFragment;
    private Fragment activeFragment;


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

        homeFragment = new HomeFragment();
        searchFragment = new SearchFragment();
        favoritesFragment = new FavoritesFragment();
        settingsFragment = new SettingsFragment();


        getSupportFragmentManager().beginTransaction()
                .add(R.id.fragment_container, settingsFragment).hide(settingsFragment)
                .add(R.id.fragment_container, favoritesFragment).hide(favoritesFragment)
                .add(R.id.fragment_container, searchFragment).hide(searchFragment)
                .add(R.id.fragment_container, homeFragment)
                .commit();

        activeFragment = homeFragment;

        BottomNavigationView bottomNav = findViewById(R.id.bottom_nav);
        bottomNav.setOnItemSelectedListener(item -> {
            Fragment target;
            int id = item.getItemId();
            if (id == R.id.nav_home) target = homeFragment;
            else if (id == R.id.nav_search) target = searchFragment;
            else if (id == R.id.nav_favorites) target = favoritesFragment;
            else if (id == R.id.nav_settings) target = settingsFragment;
            else return false;

            getSupportFragmentManager().beginTransaction()
                    .hide(activeFragment)
                    .show(target)
                    .commit();
            activeFragment = target;
            return true;
        });
    }
}
