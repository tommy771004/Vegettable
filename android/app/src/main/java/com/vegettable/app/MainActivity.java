package com.vegettable.app;

import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;

import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.vegettable.app.ui.home.HomeFragment;
import com.vegettable.app.ui.search.SearchFragment;
import com.vegettable.app.ui.favorites.FavoritesFragment;
import com.vegettable.app.ui.settings.SettingsFragment;

public class MainActivity extends AppCompatActivity {

    private HomeFragment homeFragment;
    private SearchFragment searchFragment;
    private FavoritesFragment favoritesFragment;
    private SettingsFragment settingsFragment;
    private Fragment activeFragment;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

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
