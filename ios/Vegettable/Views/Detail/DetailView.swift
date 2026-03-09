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
                SkeletonListView(count: 4)
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


                        // 日價格圖 (最近 7 天)
                        barChartCard(
                            title: "近 7 日價格走勢",
                            data: detail.dailyPrices.suffix(7).map { (formatDateLabel($0.date), $0.avgPrice) },
                            barColor: AppColors.primaryLight
                        )

                        // 月價格圖 (最近 12 個月)
                        barChartCard(
                            title: "近 3 年月均價（近 12 月）",
                            data: detail.monthlyPrices.suffix(12).map { ($0.month, $0.avgPrice) },
                            barColor: Color(hex: "#42A5F5")
                        )

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
                .refreshable { loadData() }
            } else if let error = errorMessage {
                VStack(spacing: 14) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.textTertiary)
                    Text(error)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                    Button("重試") { loadData() }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.primary)
                        .clipShape(Capsule())
                }
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
                .accessibilityLabel(settings.isFavorite(cropCode) ? "取消收藏" : "加入收藏")

                ShareLink(item: "\(cropName) — 菜價查詢 App") {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("分享")
            }
        }
        .onAppear { loadDetail() }
    }

    private func loadData() {
        loadDetail()
    }

    /// 日期格式化：「115.03.02」→「03/02」、「2023/01」保留
    private func formatDateLabel(_ raw: String) -> String {
        // 民國年格式 "115.03.02"
        if raw.contains(".") {
            let parts = raw.split(separator: ".")
            if parts.count >= 3 {
                return "\(parts[1])/\(parts[2])"
            }
        }
        // 西元格式 "2023-03-02"
        if raw.contains("-") {
            let parts = raw.split(separator: "-")
            if parts.count >= 3 {
                return "\(parts[1])/\(parts[2])"
            }
        }
        return raw
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

    // MARK: - 橫條圖卡片（不使用 GeometryReader）
    private func barChartCard(title: String, data: [(String, Double)], barColor: Color) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.primary)
                    .padding(.bottom, 12)

                if data.isEmpty {
                    Text("暫無資料")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(AppColors.textTertiary)
                        .padding(.vertical, 20)
                } else {
                    let maxVal = data.map(\.1).max() ?? 1

                    VStack(spacing: 8) {
                        ForEach(Array(data.enumerated()), id: \.0) { _, item in
                            ChartBarRow(
                                label: item.0,
                                value: item.1,
                                maxValue: maxVal,
                                barColor: barColor
                            )
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

// MARK: - 圖表列元件（固定佈局，不使用 GeometryReader）
struct ChartBarRow: View {
    let label: String
    let value: Double
    let maxValue: Double
    let barColor: Color

    private var ratio: CGFloat {
        maxValue > 0 ? CGFloat(value / maxValue) : 0
    }

    var body: some View {
        HStack(spacing: 6) {
            // 日期標籤
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(AppColors.textTertiary)
                .frame(width: 52, alignment: .leading)
                .lineLimit(1)

            // 長條 — 使用固定 maxWidth 乘以比例
            ZStack(alignment: .leading) {
                // 背景軌道
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.gray.opacity(0.08))
                    .frame(height: 18)

                // 值條
                RoundedRectangle(cornerRadius: 5)
                    .fill(
                        LinearGradient(
                            colors: [barColor.opacity(0.7), barColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(6, ratio * 180), height: 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .frame(height: 9)
                            .offset(y: -4.5)
                        , alignment: .top
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 數值
            Text(PriceUtils.formatPrice(value))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 44, alignment: .trailing)
                .lineLimit(1)
        }
        .frame(height: 24)
    }
}
