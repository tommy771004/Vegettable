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
            LiquidGlassBackground()

            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(AppColors.primary)
                        .scaleEffect(1.2)
                    Text("載入中…")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(AppColors.textTertiary)
                }
            } else if let detail = detail {
                ScrollView {
                    VStack(spacing: 14) {
                        // 別名
                        if !detail.aliases.isEmpty {
                            Text("又稱：" + detail.aliases.joined(separator: "、"))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(AppColors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                        }

                        // 主價格卡
                        priceCard(detail)

                        // 日價格圖
                        chartCard(title: "近 7 日價格走勢", prices: detail.dailyPrices.map { ($0.date, $0.avgPrice) }, color: AppColors.primaryLight)

                        // 月價格圖
                        chartCard(title: "近 3 年月均價", prices: detail.monthlyPrices.map { ($0.month, $0.avgPrice) }, color: Color(hex: "#42A5F5"))

                        // AI 預測
                        if let pred = prediction {
                            predictionCard(pred)
                        }

                        // 食譜
                        if !recipes.isEmpty {
                            recipesCard
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 40)
                }
            } else if let error = errorMessage {
                Text(error)
                    .font(.system(size: 14, design: .rounded))
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
                        .foregroundColor(settings.isFavorite(cropCode) ? .pink : .gray)
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
            VStack(spacing: 14) {
                HStack {
                    Text(PriceUtils.formatPrice(settings.displayPrice(d.avgPrice)))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(PriceUtils.priceLevelColor(d.priceLevel))

                    Text(PriceUtils.trendArrow(d.trend))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(PriceUtils.trendColor(d.trend))

                    Spacer()

                    Text(PriceUtils.priceLevelLabel(d.priceLevel))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .foregroundColor(PriceUtils.priceLevelColor(d.priceLevel))
                        .background(
                            Capsule()
                                .fill(PriceUtils.priceLevelBgColor(d.priceLevel))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(PriceUtils.priceLevelColor(d.priceLevel).opacity(0.2), lineWidth: 0.5)
                                )
                        )
                }

                Text(settings.unitLabel + "（批發）")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 分隔線 — 玻璃質感
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.white.opacity(0.5), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                HStack {
                    VStack(spacing: 4) {
                        Text("歷史均價")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(AppColors.textTertiary)
                        Text(PriceUtils.formatPrice(d.historicalAvgPrice) + " 元")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Text("交易量")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(AppColors.textTertiary)
                        let vol = d.dailyPrices.last?.volume ?? 0
                        Text(PriceUtils.formatPrice(vol) + " 公斤")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(22)
        }
    }

    // MARK: - 圖表卡片
    private func chartCard(title: String, prices: [(String, Double)], color: Color) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.primary)

                if prices.isEmpty {
                    Text("暫無資料")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(AppColors.textTertiary)
                } else {
                    let maxVal = prices.map(\.1).max() ?? 1

                    ForEach(Array(prices.enumerated()), id: \.0) { _, item in
                        HStack(spacing: 8) {
                            Text(item.0)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(AppColors.textTertiary)
                                .frame(width: 70, alignment: .leading)

                            GeometryReader { geo in
                                let width = max(0, CGFloat(item.1 / maxVal) * geo.size.width)
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(
                                        LinearGradient(
                                            colors: [color.opacity(0.8), color],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: width, height: 16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.3), Color.clear],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .frame(width: width, height: 8)
                                            .offset(y: -2)
                                        , alignment: .top
                                    )
                            }
                            .frame(height: 16)

                            Text(PriceUtils.formatPrice(item.1))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
            .padding(18)
        }
    }

    // MARK: - 預測卡片
    private func predictionCard(_ pred: PricePrediction) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(AppColors.primary)
                    Text("AI 價格預測")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.primary)
                }

                let arrow = PriceUtils.trendArrow(pred.direction)
                Text("預測價格: \(PriceUtils.formatPrice(pred.predictedPrice)) 元 \(arrow) (\(String(format: "%.1f", pred.changePercent))%)")
                    .font(.system(size: 15, design: .rounded))

                ProgressView(value: pred.confidence, total: 100) {
                    Text("信心度: \(Int(pred.confidence))%")
                        .font(.system(size: 12, design: .rounded))
                }
                .tint(AppColors.primary)

                Text(pred.reasoning)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(18)
        }
    }

    // MARK: - 食譜卡片
    private var recipesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "fork.knife")
                        .foregroundColor(AppColors.primary)
                    Text("推薦食譜")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.primary)
                }

                ForEach(recipes) { recipe in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(recipe.name)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Text("(\(recipe.cookTimeMinutes)分)")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(AppColors.textTertiary)
                        }
                        Text(recipe.description)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(18)
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
