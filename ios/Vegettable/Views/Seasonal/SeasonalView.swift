import SwiftUI

struct SeasonalView: View {
    @State private var items: [SeasonalInfo] = []
    @State private var selectedCategory: String? = nil
    @State private var isLoading = false

    private let categories = [("全部", nil as String?), ("蔬菜", "vegetable"), ("水果", "fruit")]

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            VStack(spacing: 0) {
                // 分類
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.0) { cat in
                            LiquidChip(
                                label: cat.0,
                                isSelected: selectedCategory == cat.1,
                                action: {
                                    selectedCategory = cat.1
                                    loadSeasonal()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 10)

                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(AppColors.primary)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(items) { info in
                                SeasonalRow(info: info)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationTitle("季節行事曆")
        .onAppear { loadSeasonal() }
    }

    private func loadSeasonal() {
        isLoading = true
        Task {
            do {
                let result = try await ApiClient.shared.fetchSeasonalInfo(category: selectedCategory)
                await MainActor.run {
                    items = result
                    isLoading = false
                }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }
}

struct SeasonalRow: View {
    let info: SeasonalInfo
    private let currentMonth = Calendar.current.component(.month, from: Date())

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(info.cropName)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))

                    Spacer()

                    Text(info.isInSeason ? "當季" : "非當季")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .foregroundColor(info.isInSeason ? AppColors.primary : AppColors.textTertiary)
                        .background(
                            Capsule()
                                .fill(info.isInSeason ? AppColors.primary.opacity(0.1) : Color.gray.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(
                                            info.isInSeason ? AppColors.primary.opacity(0.2) : Color.gray.opacity(0.15),
                                            lineWidth: 0.5
                                        )
                                )
                        )
                }

                // 12 月份格子
                HStack(spacing: 3) {
                    ForEach(1...12, id: \.self) { m in
                        Text("\(m)")
                            .font(.system(size: 9, weight: info.peakMonths.contains(m) ? .bold : .regular, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        info.peakMonths.contains(m)
                                            ? LinearGradient(
                                                colors: [AppColors.primaryLight, AppColors.primary],
                                                startPoint: .top,
                                                endPoint: .bottom
                                              )
                                            : (m == currentMonth
                                                ? LinearGradient(colors: [AppColors.primary.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                                                : LinearGradient(colors: [Color.white.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                                              )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5)
                                    )
                            )
                            .foregroundColor(
                                info.peakMonths.contains(m) ? .white
                                    : (m == currentMonth ? AppColors.primary : AppColors.textTertiary)
                            )
                    }
                }

                Text(info.seasonNote)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(18)
        }
    }
}
