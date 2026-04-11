import SwiftUI

struct CompareView: View {
    @State private var cropName = ""
    @State private var results: [MarketPrice] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var hasSearched = false

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
                        .accessibilityLabel("輸入作物名稱進行市場比價")
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()

                // 錯誤訊息
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        Text(error).font(.caption).foregroundColor(.orange)
                        Spacer()
                        Button(action: { errorMessage = nil; compare() }) {
                            Image(systemName: "arrow.clockwise").foregroundColor(.orange)
                        }
                        .accessibilityLabel("重試比價")
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                if isLoading {
                    Spacer()
                    ProgressView("比較中…")
                        .accessibilityLabel("正在取得市場比價資料")
                    Spacer()
                } else if results.isEmpty && hasSearched {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.textTertiary)
                        Text("找不到「\(cropName)」的比價資料")
                            .foregroundColor(AppColors.textSecondary)
                        Button(action: compare) {
                            Text("重試")
                                .foregroundColor(.white)
                                .padding(.horizontal, 24).padding(.vertical, 8)
                                .background(AppColors.primary).cornerRadius(8)
                        }
                        .accessibilityLabel("重試比價搜尋")
                    }
                    Spacer()
                } else if !hasSearched {
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
                    .refreshable { await refreshCompare() }
                }
            }
        }
        .navigationTitle("市場比價")
    }

    private func compare() {
        let name = cropName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        errorMessage = nil
        isLoading = true
        hasSearched = true
        Task {
            do {
                let result = try await ApiClient.shared.compareMarketPrices(cropName: name)
                await MainActor.run {
                    results = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "比價失敗：\(error.localizedDescription)"
                }
            }
        }
    }

    @MainActor
    private func refreshCompare() async {
        let name = cropName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        do {
            results = try await ApiClient.shared.compareMarketPrices(cropName: name)
        } catch {
            errorMessage = "重新整理失敗：\(error.localizedDescription)"
        }
    }
}
