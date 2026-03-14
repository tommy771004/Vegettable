package com.vegettable.app.ui.settings

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.CompoundButton
import androidx.fragment.app.Fragment
import com.google.android.material.button.MaterialButton
import com.google.android.material.button.MaterialButtonToggleGroup
import com.google.android.material.button.MaterialButtonToggleGroup.OnButtonCheckedListener
import com.google.android.material.materialswitch.MaterialSwitch
import com.vegettable.app.R
import com.vegettable.app.ui.compare.CompareActivity
import com.vegettable.app.ui.map.MapActivity
import com.vegettable.app.ui.seasonal.SeasonalActivity
import com.vegettable.app.util.PrefsManager

class SettingsFragment : Fragment() {
    private var prefs: PrefsManager? = null

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_settings, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        prefs = PrefsManager(requireContext())

        // ─── 價格單位 ─────────────────────────────────────────
        val toggleUnit = view.findViewById<MaterialButtonToggleGroup>(R.id.toggle_unit)
        val btnKg = view.findViewById<MaterialButton?>(R.id.btn_kg)
        val btnCatty = view.findViewById<MaterialButton?>(R.id.btn_catty)

        if ("catty" == prefs!!.priceUnit) {
            toggleUnit.check(R.id.btn_catty)
        } else {
            toggleUnit.check(R.id.btn_kg)
        }

        toggleUnit.addOnButtonCheckedListener(OnButtonCheckedListener { group: MaterialButtonToggleGroup?, checkedId: Int, isChecked: Boolean ->
            if (isChecked) {
                prefs!!.priceUnit = if (checkedId == R.id.btn_catty) "catty" else "kg"
            }
        })

        // ─── 零售價格開關 ─────────────────────────────────────
        val switchRetail = view.findViewById<MaterialSwitch>(R.id.switch_retail)
        switchRetail.setChecked(prefs!!.isShowRetailPrice)
        switchRetail.setOnCheckedChangeListener(CompoundButton.OnCheckedChangeListener { buttonView: CompoundButton?, isChecked: Boolean ->
            prefs!!.isShowRetailPrice = isChecked
        })

        // ─── 快捷功能 ─────────────────────────────────────────
        view.findViewById<View?>(R.id.btn_seasonal)
            .setOnClickListener(View.OnClickListener { v: View? ->
                startActivity(
                    Intent(
                        requireContext(),
                        SeasonalActivity::class.java
                    )
                )
            })

        view.findViewById<View?>(R.id.btn_compare)
            .setOnClickListener(View.OnClickListener { v: View? ->
                startActivity(
                    Intent(
                        requireContext(),
                        CompareActivity::class.java
                    )
                )
            })

        view.findViewById<View?>(R.id.btn_map).setOnClickListener(View.OnClickListener { v: View? ->
            startActivity(
                Intent(
                    requireContext(),
                    MapActivity::class.java
                )
            )
        })
    }
}
