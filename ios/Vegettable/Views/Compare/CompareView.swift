import SwiftUI

struct CompareView: View {
    @State private var cropName = ""
    @State private var results: [MarketPrice] = []
    @State private var isLoading = false

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            VStack(spacing: 0) {
                // Liquid Glass 搜尋框
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textTertiary)
                    TextField("輸入作物名稱進行比價", text: $cropName)
                        .font(.system(size: 15, design: .rounded))
                        .onSubmit { compare() }
                }
                .padding(14)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.4))
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 0.8)
                    }
                )
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                .padding(.horizontal, 14)
                .padding(.top, 4)

                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(AppColors.primary)
                    Spacer()
                } else if results.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.xaxis.ascending")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.textTertiary.opacity(0.5))
                        Text("輸入作物名稱後按 Enter 開始比價")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(results) { mp in
                                GlassCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(mp.marketName)
                                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                            Text(mp.transDate)
                                                .font(.system(size: 12, design: .rounded))
                                                .foregroundColor(AppColors.textTertiary)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 5) {
                                            Text(PriceUtils.formatPrice(mp.avgPrice) + " 元/公斤")
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .foregroundColor(AppColors.primary)
                                            Text("\(PriceUtils.formatPrice(mp.lowerPrice)) ~ \(PriceUtils.formatPrice(mp.upperPrice))")
                                                .font(.system(size: 11, design: .rounded))
                                                .foregroundColor(AppColors.textTertiary)
                                        }
                                    }
                                    .padding(18)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 10)
                        .padding(.bottom, 24)
                    }
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
