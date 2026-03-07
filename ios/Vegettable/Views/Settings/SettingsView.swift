import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [AppColors.background, AppColors.backgroundEnd],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {

                        // ─── 價格顯示 ───────────────────────
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("價格顯示", systemImage: "dollarsign.circle")
                                    .font(.headline)
                                    .foregroundColor(AppColors.primary)

                                HStack {
                                    Text("價格單位")
                                    Spacer()
                                    Picker("", selection: $settings.priceUnit) {
                                        Text("公斤").tag("kg")
                                        Text("台斤").tag("catty")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 150)
                                }

                                Toggle("顯示估計零售價", isOn: $settings.showRetailPrice)
                            }
                            .padding(16)
                        }

                        // ─── 快捷功能 ───────────────────────
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("快捷功能", systemImage: "star.fill")
                                    .font(.headline)
                                    .foregroundColor(AppColors.primary)

                                NavigationLink(destination: SeasonalView()) {
                                    SettingsRow(icon: "calendar", title: "季節行事曆", color: .green)
                                }

                                NavigationLink(destination: CompareView()) {
                                    SettingsRow(icon: "chart.bar.xaxis", title: "市場比價", color: .blue)
                                }

                                NavigationLink(destination: MapListView()) {
                                    SettingsRow(icon: "map", title: "附近市場", color: .orange)
                                }
                            }
                            .padding(16)
                        }

                        // ─── 關於 ────────────────────────────
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("關於", systemImage: "info.circle")
                                    .font(.headline)
                                    .foregroundColor(AppColors.primary)

                                Text("資料來源：行政院農業委員會")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)

                                Text("價格資料僅供參考，實際交易價格以市場為準")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.textTertiary)

                                Text("v2.0")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                            .padding(16)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
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
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(title)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.vertical, 8)
    }
}
