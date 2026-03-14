package com.vegettable.app

import android.os.Bundle
import android.view.MenuItem
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.google.android.material.navigation.NavigationBarView
import com.vegettable.app.ui.favorites.FavoritesFragment
import com.vegettable.app.ui.home.HomeFragment
import com.vegettable.app.ui.search.SearchFragment
import com.vegettable.app.ui.settings.SettingsFragment

class MainActivity : AppCompatActivity() {
    private val fragmentManager = supportFragmentManager
    private var currentFragment: Fragment? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val bottomNav = findViewById<BottomNavigationView>(R.id.bottom_nav)

        if (savedInstanceState == null) {
            loadFragment(HomeFragment(), false)
        } else {
            currentFragment = fragmentManager.findFragmentById(R.id.fragment_container)
        }

        bottomNav.setOnItemSelectedListener { item ->
            val fragment: Fragment? = when (item.itemId) {
                R.id.nav_home -> HomeFragment()
                R.id.nav_search -> SearchFragment()
                R.id.nav_favorites -> FavoritesFragment()
                R.id.nav_settings -> SettingsFragment()
                else -> null
            }

            fragment?.let {
                loadFragment(it, true)
                true
            } ?: false
        }
    }

    private fun loadFragment(fragment: Fragment, addToBackStack: Boolean) {
        val transaction = fragmentManager.beginTransaction()
        transaction.replace(R.id.fragment_container, fragment)

        if (addToBackStack) {
            transaction.addToBackStack(null)
        }

        transaction.commit()
        currentFragment = fragment
    }

    override fun onBackPressed() {
        if (fragmentManager.backStackEntryCount > 0) {
            fragmentManager.popBackStack()
        } else {
            super.onBackPressed()
        }
    }
}