import SwiftUI

struct FlowerView: View {
    @State private var prices: [FlowerPrice] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedMarket: String = "全部"

    private var markets: [String] {
        let all = prices.map { $0.marketName }
        return ["全部"] + Array(Set(all)).sorted()
    }

    private var filtered: [FlowerPrice] {
        prices.filter { item in
            let matchesMarket = selectedMarket == "全部" || item.marketName == selectedMarket
            let matchesSearch = searchText.isEmpty ||
                item.flowerName.contains(searchText) ||
                item.flowerType.contains(searchText)
            return matchesMarket && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#FCE4EC"), Color(hex: "#F8BBD9")],
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
                                .tint(Color(hex: "#C2185B"))
                        }
                        .padding()
                        Spacer()
                    } else if filtered.isEmpty {
                        Spacer()
                        Text(searchText.isEmpty ? "目前無花卉行情資料" : "找不到相關花卉")
                            .foregroundColor(AppColors.textTertiary)
                        Spacer()
                    } else {
                        List {
                            ForEach(filtered) { item in
                                FlowerRow(item: item)
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
            .navigationTitle("花卉行情")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "搜尋花卉名稱或種類")
            .task { await loadPrices() }
        }
    }

    private func loadPrices() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await ApiClient.shared.fetchFlowerPrices()
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

struct FlowerRow: View {
    let item: FlowerPrice

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(Color(hex: "#E91E63"))
                        .font(.caption)
                    Text(item.flowerName)
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                }
                if !item.flowerType.isEmpty {
                    Text(item.flowerType)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "#FCE4EC"))
                        .foregroundColor(Color(hex: "#C2185B"))
                        .clipShape(Capsule())
                }
                Text(item.marketName)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
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
                Text("元/把")
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)
                Text("量: \(String(format: "%.0f", NSDecimalNumber(decimal: item.volume).doubleValue))")
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

#Preview {
    FlowerView()
}
