import SwiftUI

struct DetailView: View {
    let cropName: String
    let cropCode: String

    @EnvironmentObject var settings: SettingsManager
    @State private var detail: ProductDetail?
    @State private var prediction: PricePrediction?
    @State private var recipes: [Recipe] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppColors.background, AppColors.backgroundEnd],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            if isLoading {
                ProgressView("載入中…")
            } else if let detail = detail {
                ScrollView {
                    VStack(spacing: 12) {
                        // 別名
                        if !detail.aliases.isEmpty {
                            Text("又稱：" + detail.aliases.joined(separator: "、"))
                                .font(.caption)
                                .foregroundColor(AppColors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                        }

                        // 主價格卡
                        priceCard(detail)

                        // 日價格圖
                        chartCard(title: "近 7 日價格走勢", prices: detail.dailyPrices.map { ($0.date, $0.avgPrice) }, color: AppColors.primaryLight)

                        // 月價格圖
                        chartCard(title: "近 3 年月均價", prices: detail.monthlyPrices.map { ($0.month, $0.avgPrice) }, color: .blue)

                        // AI 預測
                        if let pred = prediction {
                            predictionCard(pred)
                        }

                        // 食譜
                        if !recipes.isEmpty {
                            recipesCard
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .navigationTitle(cropName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    settings.toggleFavorite(cropCode)
                } label: {
                    Image(systemName: settings.isFavorite(cropCode) ? "heart.fill" : "heart")
                        .foregroundColor(settings.isFavorite(cropCode) ? .red : .gray)
                }

                ShareLink(item: "\(cropName) — 菜價查詢 App") {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .onAppear { loadDetail() }
    }

    // MARK: - 價格卡片
    private func priceCard(_ d: ProductDetail) -> some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    Text(PriceUtils.formatPrice(settings.displayPrice(d.avgPrice)))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(PriceUtils.priceLevelColor(d.priceLevel))

                    Text(PriceUtils.trendArrow(d.trend))
                        .font(.title2)
                        .foregroundColor(PriceUtils.trendColor(d.trend))

                    Spacer()

                    Text(PriceUtils.priceLevelLabel(d.priceLevel))
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .foregroundColor(PriceUtils.priceLevelColor(d.priceLevel))
                        .background(PriceUtils.priceLevelBgColor(d.priceLevel))
                        .clipShape(Capsule())
                }

                Text(settings.unitLabel + "（批發）")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                HStack {
                    VStack {
                        Text("歷史均價").font(.caption2).foregroundColor(AppColors.textTertiary)
                        Text(PriceUtils.formatPrice(d.historicalAvgPrice) + " 元")
                            .font(.callout).fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)

                    VStack {
                        Text("交易量").font(.caption2).foregroundColor(AppColors.textTertiary)
                        let vol = d.dailyPrices.last?.volume ?? 0
                        Text(PriceUtils.formatPrice(vol) + " 公斤")
                            .font(.callout).fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
    }

    // MARK: - 圖表卡片
    private func chartCard(title: String, prices: [(String, Double)], color: Color) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)

                if prices.isEmpty {
                    Text("暫無資料").font(.caption).foregroundColor(AppColors.textTertiary)
                } else {
                    let maxVal = prices.map(\.1).max() ?? 1

                    ForEach(Array(prices.enumerated()), id: \.0) { _, item in
                        HStack(spacing: 8) {
                            Text(item.0)
                                .font(.caption2)
                                .foregroundColor(AppColors.textTertiary)
                                .frame(width: 70, alignment: .leading)

                            GeometryReader { geo in
                                let width = max(0, CGFloat(item.1 / maxVal) * geo.size.width)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(color)
                                    .frame(width: width, height: 14)
                            }
                            .frame(height: 14)

                            Text(PriceUtils.formatPrice(item.1))
                                .font(.caption2)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - 預測卡片
    private func predictionCard(_ pred: PricePrediction) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("AI 價格預測")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)

                let arrow = PriceUtils.trendArrow(pred.direction)
                Text("預測價格: \(PriceUtils.formatPrice(pred.predictedPrice)) 元 \(arrow) (\(String(format: "%.1f", pred.changePercent))%)")
                    .font(.callout)

                ProgressView(value: pred.confidence, total: 100) {
                    Text("信心度: \(Int(pred.confidence))%")
                        .font(.caption2)
                }
                .tint(AppColors.primary)

                Text(pred.reasoning)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(16)
        }
    }

    // MARK: - 食譜卡片
    private var recipesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("推薦食譜")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)

                ForEach(recipes) { recipe in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(recipe.name)
                                .font(.callout).fontWeight(.medium)
                            Text("(\(recipe.cookTimeMinutes)分)")
                                .font(.caption)
                                .foregroundColor(AppColors.textTertiary)
                        }
                        Text(recipe.description)
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(16)
        }
    }

    // MARK: - 載入資料
    private func loadDetail() {
        isLoading = true
        Task {
            do {
                async let detailTask = ApiClient.shared.fetchProductDetail(cropName: cropName)
                async let predTask: PricePrediction? = {
                    try? await ApiClient.shared.fetchPrediction(cropName: cropName)
                }()
                async let recipesTask: [Recipe] = {
                    (try? await ApiClient.shared.fetchRecipes(cropName: cropName)) ?? []
                }()

                let (d, p, r) = await (try detailTask, predTask, recipesTask)

                await MainActor.run {
                    detail = d
                    prediction = p
                    recipes = r
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "載入失敗: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}
