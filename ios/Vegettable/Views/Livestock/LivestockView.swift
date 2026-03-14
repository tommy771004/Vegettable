import SwiftUI

struct LivestockView: View {
    @State private var prices: [LivestockPrice] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedMarket: String = "全部"

    private var markets: [String] {
        let all = prices.map { $0.marketName }
        return ["全部"] + Array(Set(all)).sorted()
    }

    private var filtered: [LivestockPrice] {
        prices.filter { item in
            let matchesMarket = selectedMarket == "全部" || item.marketName == selectedMarket
            let matchesSearch = searchText.isEmpty || item.livestockName.contains(searchText)
            return matchesMarket && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#FBE9E7"), Color(hex: "#FFCCBC")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 市場篩選
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(markets, id: \.self) { market in
                                CategoryChip(
                                    label: market,
                                    isSelected: selectedMarket == market,
                                    action: { selectedMarket = market }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)

                    if isLoading && prices.isEmpty {
                        SkeletonListView(count: 8)
                    } else if let error = errorMessage, prices.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(AppColors.textTertiary)
                            Text(error)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                            Button("重試") { Task { await loadPrices() } }
                                .buttonStyle(.borderedProminent)
                                .tint(Color(hex: "#BF360C"))
                        }
                        .padding()
                        Spacer()
                    } else if filtered.isEmpty {
                        Spacer()
                        Text(searchText.isEmpty ? "目前無畜產品行情資料" : "找不到相關畜產品")
                            .foregroundColor(AppColors.textTertiary)
                        Spacer()
                    } else {
                        List {
                            ForEach(filtered) { item in
                                LivestockRow(item: item)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                            }
                        }
                        .listStyle(.plain)
                        .refreshable { await loadPrices() }
                    }
                }
            }
            .navigationTitle("畜產品行情")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "搜尋畜產品名稱")
            .task { await loadPrices() }
        }
    }

    private func loadPrices() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await ApiClient.shared.fetchLivestockPrices()
            await MainActor.run {
                prices = result
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct LivestockRow: View {
    let item: LivestockPrice

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.livestockName)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Text(item.marketName)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                HStack(spacing: 8) {
                    Label("\(item.headCount) 頭", systemImage: "number")
                        .font(.caption2)
                        .foregroundColor(AppColors.textTertiary)
                    Label(String(format: "均重 %.1f kg", NSDecimalNumber(decimal: item.avgWeight).doubleValue), systemImage: "scalemass")
                        .font(.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
                Text(item.transDate)
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", NSDecimalNumber(decimal: item.avgPrice).doubleValue))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(PriceUtils.trendColor(item.trend))
                    Text(PriceUtils.trendArrow(item.trend))
                        .foregroundColor(PriceUtils.trendColor(item.trend))
                }
                Text("元/公斤")
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)
                HStack(spacing: 4) {
                    Text("↑\(String(format: "%.0f", NSDecimalNumber(decimal: item.upperPrice).doubleValue))")
                        .font(.caption2)
                        .foregroundColor(.red.opacity(0.7))
                    Text("↓\(String(format: "%.0f", NSDecimalNumber(decimal: item.lowerPrice).doubleValue))")
                        .font(.caption2)
                        .foregroundColor(.green.opacity(0.7))
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

#Preview {
    LivestockView()
}
