import SwiftUI

struct SeasonalView: View {
    @State private var items: [SeasonalInfo] = []
    @State private var selectedCategory: String? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    private let logger = DebugLogger.shared
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

                // 錯誤提示
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                        Button(action: { errorMessage = nil; loadSeasonal() }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                if isLoading {
                    Spacer()
                    ProgressView()
                        .accessibilityLabel("正在加載季節信息")
                    Spacer()
                } else if items.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.textTertiary)
                        Text("未找到季節信息")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(items) { info in
                            SeasonalRow(info: info)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .accessibilityElement(children: .contain)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await refreshSeasonal() }
                }
            }
        }
        .navigationTitle("季節行事曆")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadSeasonal() }
    }

    @MainActor
    private func refreshSeasonal() async {
        do {
            let result = try await ApiClient.shared.fetchSeasonalInfo(category: selectedCategory)
            items = result
            errorMessage = nil
        } catch {
            errorMessage = "重新整理失敗: \(error.localizedDescription)"
        }
    }

    private func loadSeasonal() {
        isLoading = true
        errorMessage = nil
        logger.debug("加載季節信息，分類: \(selectedCategory ?? \"全部")")
        
        Task {
            do {
                let result = try await ApiClient.shared.fetchSeasonalInfo(category: selectedCategory)
                await MainActor.run {
                    items = result
                    isLoading = false
                    logger.info("季節信息加載完成: \(result.count) 項")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "加載失敗: \(error.localizedDescription)"
                    logger.error("季節信息加載失敗: \(error.localizedDescription)")
                }
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
                        .accessibilityLabel("蔬果名稱: \(info.cropName)")

                    Spacer()

                    Text(info.isInSeason ? "當季" : "非當季")
                        .font(.caption2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .foregroundColor(info.isInSeason ? AppColors.primary : .gray)
                        .background(info.isInSeason ? AppColors.primary.opacity(0.1) : Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                        .accessibilityLabel(info.isInSeason ? "目前當季" : "目前非當季")
                }

                // 12 月份格子
                VStack(spacing: 4) {
                    Text("產季: ")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    HStack(spacing: 2) {
                        ForEach(1...12, id: \.self) { m in
                            VStack(spacing: 2) {
                                Text("\(m)")
                                    .font(.system(size: 9, weight: .semibold))
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
                                    .accessibilityLabel("\(m)月: \(info.peakMonths.contains(m) ? \"盛產期\" : \"非盛產期")")
                            }
                        }
                    }
                }

                Text(info.seasonNote)
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)
                    .accessibilityLabel("季節備註: \(info.seasonNote)")
            }
            .padding(16)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SeasonalView()
    }
}