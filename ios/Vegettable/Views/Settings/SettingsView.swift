import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 14) {

                        // ─── 價格顯示 ───────────────────────
                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 8) {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [AppColors.primary, AppColors.primaryLight],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Text("價格顯示")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                }

                                HStack {
                                    Text("價格單位")
                                        .font(.system(size: 15, design: .rounded))
                                    Spacer()
                                    Picker("", selection: $settings.priceUnit) {
                                        Text("公斤").tag("kg")
                                        Text("台斤").tag("catty")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 150)
                                }

                                Toggle(isOn: $settings.showRetailPrice) {
                                    Text("顯示估計零售價")
                                        .font(.system(size: 15, design: .rounded))
                                }
                                .tint(AppColors.primary)
                            }
                            .padding(18)
                        }

                        // ─── 快捷功能 ───────────────────────
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "star.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.orange, Color.yellow],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Text("快捷功能")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                }

                                NavigationLink(destination: SeasonalView()) {
                                    SettingsRow(icon: "calendar.circle.fill", title: "季節行事曆", color: .green)
                                }

                                NavigationLink(destination: CompareView()) {
                                    SettingsRow(icon: "chart.bar.xaxis.ascending", title: "市場比價", color: .blue)
                                }

                                NavigationLink(destination: MapListView()) {
                                    SettingsRow(icon: "map.circle.fill", title: "附近市場", color: .orange)
                                }
                            }
                            .padding(18)
                        }

                        // ─── 關於 ────────────────────────────
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.blue, Color.cyan],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Text("關於")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                }

                                Text("資料來源：行政院農業委員會")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(AppColors.textSecondary)

                                Text("價格資料僅供參考，實際交易價格以市場為準")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(AppColors.textTertiary)

                                Text("v2.0 — 液態玻璃設計")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(AppColors.textTertiary)
                            }
                            .padding(18)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28)

            Text(title)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textTertiary.opacity(0.6))
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}
