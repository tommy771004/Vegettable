package com.vegettable.app.ui.settings;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.google.android.material.button.MaterialButton;
import com.google.android.material.button.MaterialButtonToggleGroup;
import com.google.android.material.materialswitch.MaterialSwitch;
import com.vegettable.app.R;
import com.vegettable.app.ui.seasonal.SeasonalActivity;
import com.vegettable.app.ui.compare.CompareActivity;
import com.vegettable.app.ui.map.MapActivity;
import com.vegettable.app.util.PrefsManager;

public class SettingsFragment extends Fragment {

    private PrefsManager prefs;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_settings, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        prefs = new PrefsManager(requireContext());

        // ─── 價格單位 ─────────────────────────────────────────
        MaterialButtonToggleGroup toggleUnit = view.findViewById(R.id.toggle_unit);
        MaterialButton btnKg = view.findViewById(R.id.btn_kg);
        MaterialButton btnCatty = view.findViewById(R.id.btn_catty);

        if ("catty".equals(prefs.getPriceUnit())) {
            toggleUnit.check(R.id.btn_catty);
        } else {
            toggleUnit.check(R.id.btn_kg);
        }

        toggleUnit.addOnButtonCheckedListener((group, checkedId, isChecked) -> {
            if (isChecked) {
                prefs.setPriceUnit(checkedId == R.id.btn_catty ? "catty" : "kg");
            }
        });

        // ─── 零售價格開關 ─────────────────────────────────────
        MaterialSwitch switchRetail = view.findViewById(R.id.switch_retail);
        switchRetail.setChecked(prefs.isShowRetailPrice());
        switchRetail.setOnCheckedChangeListener((buttonView, isChecked) ->
                prefs.setShowRetailPrice(isChecked));

        // ─── 快捷功能 ─────────────────────────────────────────
        view.findViewById(R.id.btn_seasonal).setOnClickListener(v ->
                startActivity(new Intent(requireContext(), SeasonalActivity.class)));

        view.findViewById(R.id.btn_compare).setOnClickListener(v ->
                startActivity(new Intent(requireContext(), CompareActivity.class)));

        view.findViewById(R.id.btn_map).setOnClickListener(v ->
                startActivity(new Intent(requireContext(), MapActivity.class)));
    }
}
