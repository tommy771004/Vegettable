import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var showClearCacheAlert = false
    @State private var showFeedbackSheet = false
    @State private var cacheCleared = false
    @State private var cacheSize = "計算中..."
    @Environment(\.colorScheme) var colorScheme
    private let logger = DebugLogger.shared

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [AppColors.background, AppColors.backgroundEnd],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        // ─── 價格顯示 ───────────────────────
                        makePriceSection()

                        // ─── 主題與外觀 ────────────────────
                        makeAppearanceSection()

                        // ─── 快捷功能 ───────────────────────
                        makeQuickAccessSection()

                        // ─── 數據管理 ────────────────────────
                        makeDataManagementSection()

                        // ─── 反饋與幫助 ────────────────────
                        makeFeedbackSection()

                        // ─── 關於 ────────────────────────────
                        makeAboutSection()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .alert("清除快取", isPresented: $showClearCacheAlert) {
                Button("取消", role: .cancel) { }
                Button("確認清除", role: .destructive) {
                    clearCache()
                }
            } message: {
                Text("確定要清除所有已快取的資料嗎？此操作無法復原。\n快取大小: \(cacheSize)")
            }
            .onAppear {
                calculateCacheSize()
            }
        }
    }

    // MARK: - Section Builders

    @ViewBuilder
    private func makePriceSection() -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("價格顯示", systemImage: "dollarsign.circle")
                    .font(.headline)
                    .foregroundColor(AppColors.primary)
                    .accessibilityAddTraits(.isHeader)

                HStack {
                    Text("價格單位")
                        .accessibilityLabel("選擇價格計價單位")
                    Spacer()
                    Picker("價格單位", selection: $settings.priceUnit) {
                        Text("公斤").tag("kg")
                        Text("台斤").tag("catty")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                    .accessibilityLabel("價格單位選擇")
                }

                Toggle("顯示估計零售價", isOn: $settings.showRetailPrice)
                    .accessibilityLabel("顯示估計零售價")
                    .accessibilityHint("開啟後將顯示根據批發價估計的零售價格")
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func makeAppearanceSection() -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("外觀", systemImage: "paintbrush")
                    .font(.headline)
                    .foregroundColor(AppColors.primary)
                    .accessibilityAddTraits(.isHeader)

                HStack {
                    Text("深色模式")
                        .accessibilityLabel("深色模式設定")
                    Spacer()
                    Picker("深色模式", selection: $settings.preferredColorScheme) {
                        Text("系統").tag(Optional<ColorScheme>.none)
                        Text("淺色").tag(Optional<ColorScheme>.light)
                        Text("深色").tag(Optional<ColorScheme>.dark)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("深色模式選擇")
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func makeQuickAccessSection() -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("快捷功能", systemImage: "star.fill")
                    .font(.headline)
                    .foregroundColor(AppColors.primary)
                    .accessibilityAddTraits(.isHeader)

                NavigationLink(value: "seasonal") {
                    SettingsRow(icon: "calendar", title: "季節行事曆", color: .green)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("季節行事曆")
                        .accessibilityHint("查看各蔬菜的季節性資訊")
                }
                .navigationDestination(value: "seasonal") {
                    SeasonalView()
                }

                NavigationLink(value: "compare") {
                    SettingsRow(icon: "chart.bar.xaxis", title: "市場比價", color: .blue)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("市場比價")
                        .accessibilityHint("比較不同市場的價格")
                }
                .navigationDestination(value: "compare") {
                    CompareView()
                }

                NavigationLink(value: "map") {
                    SettingsRow(icon: "map", title: "附近市場", color: .orange)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("附近市場")
                        .accessibilityHint("查看附近的農產品市場")
                }
                .navigationDestination(value: "map") {
                    MapListView()
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func makeDataManagementSection() -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("數據管理", systemImage: "internaldrive")
                    .font(.headline)
                    .foregroundColor(AppColors.primary)
                    .accessibilityAddTraits(.isHeader)

                Button(action: { showClearCacheAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("清除快取資料")
                                .foregroundColor(AppColors.textPrimary)
                            Text("大小: \(cacheSize)")
                                .font(.caption2)
                                .foregroundColor(AppColors.textTertiary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("清除快取資料")
                .accessibilityHint("刪除所有已快取的蔬菜價格和市場資訊，大小: \(cacheSize)")

                if cacheCleared {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)
                        Text("快取已清除")
                            .font(.caption)
                            .foregroundColor(AppColors.success)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                Toggle("自動更新", isOn: $settings.autoUpdate)
                    .accessibilityLabel("自動更新")
                    .accessibilityHint("應用程式啟動時自動更新最新價格資料")
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func makeFeedbackSection() -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("反饋與幫助", systemImage: "questionmark.circle")
                    .font(.headline)
                    .foregroundColor(AppColors.primary)
                    .accessibilityAddTraits(.isHeader)

                Button(action: { showFeedbackSheet = true }) {
                    HStack {
                        Image(systemName: "bubble.right")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("提交反饋")
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("提交反饋")
                .accessibilityHint("將你的建議和問題發送給開發團隊")
            }
            .padding(16)
        }
        .sheet(isPresented: $showFeedbackSheet) {
            FeedbackView(isPresented: $showFeedbackSheet)
        }
    }

    @ViewBuilder
    private func makeAboutSection() -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("關於", systemImage: "info.circle")
                    .font(.headline)
                    .foregroundColor(AppColors.primary)
                    .accessibilityAddTraits(.isHeader)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("資料來源")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text("行政院農業委員會")
                            .font(.caption)
                            .foregroundColor(AppColors.textPrimary)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    HStack {
                        Text("版本")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text("2.1")
                            .font(.caption)
                            .foregroundColor(AppColors.textPrimary)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    HStack {
                        Text("上次更新")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        let updateTime = settings.cacheTime == .distantPast
                            ? "尚未更新"
                            : DateFormatter.localizedString(from: settings.cacheTime, dateStyle: .medium, timeStyle: .short)
                        Text(updateTime)
                            .font(.caption)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("免責聲明")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textSecondary)

                    Text("價格資料僅供參考，實際交易價格以市場為準。本應用程式不對價格準確性負責。")
                        .font(.caption2)
                        .foregroundColor(AppColors.textTertiary)
                        .lineLimit(4)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Actions

    private func calculateCacheSize() {
        Task {
            do {
                let size = try await estimateCacheSize()
                await MainActor.run {
                    cacheSize = formatBytes(size)
                }
            } catch {
                await MainActor.run {
                    cacheSize = "未知"
                }
            }
        }
    }

    private func estimateCacheSize() async throws -> Int {
        // 計算 UserDefaults 大小
        let defaults = UserDefaults.standard
        var totalSize = 0
        
        if let dict = defaults.dictionaryRepresentation() as? [String: Any] {
            for (_, value) in dict {
                if let data = try? JSONSerialization.data(withJSONObject: value) {
                    totalSize += data.count
                }
            }
        }
        
        return totalSize
    }

    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }

    private func clearCache() {
        logger.debug("開始清除快取")
        
        // 清除 UserDefaults 中的快取數據
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
        }
        
        // 重新計算快取大小
        cacheCleared = true
        cacheSize = "0 B"
        logger.info("快取清除完成")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            cacheCleared = false
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

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
}
