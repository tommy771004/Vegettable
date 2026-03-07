import SwiftUI

struct CompareView: View {
    @State private var cropName = ""
    @State private var results: [MarketPrice] = []
    @State private var isLoading = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppColors.background, AppColors.backgroundEnd],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 搜尋框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textTertiary)
                    TextField("輸入作物名稱進行比價", text: $cropName)
                        .onSubmit { compare() }
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if results.isEmpty {
                    Spacer()
                    Text("輸入作物名稱後按 Enter 開始比價")
                        .foregroundColor(AppColors.textTertiary)
                    Spacer()
                } else {
                    List {
                        ForEach(results) { mp in
                            GlassCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(mp.marketName)
                                            .font(.headline)
                                        Text(mp.transDate)
                                            .font(.caption)
                                            .foregroundColor(AppColors.textTertiary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(PriceUtils.formatPrice(mp.avgPrice) + " 元/公斤")
                                            .font(.callout)
                                            .fontWeight(.bold)
                                            .foregroundColor(AppColors.primary)
                                        Text("\(PriceUtils.formatPrice(mp.lowerPrice)) ~ \(PriceUtils.formatPrice(mp.upperPrice))")
                                            .font(.caption2)
                                            .foregroundColor(AppColors.textTertiary)
                                    }
                                }
                                .padding(16)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("市場比價")
    }

    private func compare() {
        let name = cropName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        isLoading = true
        Task {
            do {
                let result = try await ApiClient.shared.compareMarketPrices(cropName: name)
                await MainActor.run {
                    results = result
                    isLoading = false
                }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }
}
