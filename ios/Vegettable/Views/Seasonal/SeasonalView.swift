import SwiftUI

struct SeasonalView: View {
    @State private var items: [SeasonalInfo] = []
    @State private var selectedCategory: String? = nil
    @State private var isLoading = false

    private let categories = [("全部", nil as String?), ("蔬菜", "vegetable"), ("水果", "fruit")]

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppColors.background, AppColors.backgroundEnd],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 分類
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.0) { cat in
                            CategoryChip(
                                label: cat.0,
                                isSelected: selectedCategory == cat.1,
                                action: {
                                    selectedCategory = cat.1
                                    loadSeasonal()
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    List {
                        ForEach(items) { info in
                            SeasonalRow(info: info)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(info.cropName)
                        .font(.headline)

                    Spacer()

                    Text(info.isInSeason ? "當季" : "非當季")
                        .font(.caption2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .foregroundColor(info.isInSeason ? AppColors.primary : .gray)
                        .background(info.isInSeason ? AppColors.primary.opacity(0.1) : Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                }

                // 12 月份格子
                HStack(spacing: 2) {
                    ForEach(1...12, id: \.self) { m in
                        Text("\(m)")
                            .font(.system(size: 9))
                            .frame(maxWidth: .infinity)
                            .frame(height: 24)
                            .background(
                                info.peakMonths.contains(m)
                                    ? AppColors.primaryLight
                                    : (m == currentMonth ? AppColors.background : Color(hex: "#F5F5F5"))
                            )
                            .foregroundColor(
                                info.peakMonths.contains(m) ? .white
                                    : (m == currentMonth ? AppColors.primary : AppColors.textTertiary)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }

                Text(info.seasonNote)
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(16)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}
