import SwiftUI
import Charts

struct DetailView: View {
    let cropName: String
    let cropCode: String

    @EnvironmentObject var settings: SettingsManager
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var detail: ProductDetail?
    @State private var prediction: PricePrediction?
    @State private var recipes: [Recipe] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var predictionFailed = false
    @State private var recipesFailed = false
    @State private var showAlertSheet = false
    private let logger = LoggerManager.shared

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
                        } else if predictionFailed {
                            sectionErrorView(icon: "brain", text: "價格預測暫時無法使用")
                        }

                        // 食譜
                        if !recipes.isEmpty {
                            recipesCard
                        } else if recipesFailed {
                            sectionErrorView(icon: "fork.knife", text: "食譜資料暫時無法載入")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(AppColors.textTertiary)
                    Text(error)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                    Button("重試") {
                        loadDetail()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                }
                .padding()
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
                .accessibilityLabel(settings.isFavorite(cropCode) ? "取消收藏" : "加入收藏")

                if let d = detail {
                    Button {
                        showAlertSheet = true
                    } label: {
                        Image(systemName: "bell.badge")
                            .foregroundColor(AppColors.primary)
                    }
                    .accessibilityLabel("設定價格警示")
                    .sheet(isPresented: $showAlertSheet) {
                        PriceAlertSheet(
                            cropName: cropName,
                            currentPrice: d.avgPrice,
                            isPresented: $showAlertSheet
                        )
                        .environmentObject(settings)
                    }
                }

                if let d = detail {
                    let shareText = "\(cropName) 目前均價 \(PriceUtils.formatPrice(d.avgPrice)) 元/公斤（\(d.trend == "up" ? "↑" : d.trend == "down" ? "↓" : "→") \(d.priceLevel)）— 蔬果行情 App"
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("分享價格資訊")
                } else {
                    ShareLink(item: "\(cropName) — 蔬果行情 App") {
                        Image(systemName: "square.and.arrow.up")
                    }
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

    // MARK: - 圖表卡片（SwiftCharts 互動折線圖）
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
                    Chart {
                        ForEach(Array(prices.enumerated()), id: \.0) { index, item in
                            LineMark(
                                x: .value("日期", index),
                                y: .value("價格", item.1)
                            )
                            .foregroundStyle(color)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("日期", index),
                                y: .value("價格", item.1)
                            )
                            .foregroundStyle(color.opacity(0.12))
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("日期", index),
                                y: .value("價格", item.1)
                            )
                            .foregroundStyle(color)
                            .symbolSize(30)
                            .annotation(position: .top, spacing: 4) {
                                Text(PriceUtils.formatPrice(item.1))
                                    .font(.caption2)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: min(prices.count, 5))) { value in
                            if let index = value.as(Int.self), index < prices.count {
                                AxisValueLabel {
                                    Text(prices[index].0)
                                        .font(.caption2)
                                        .foregroundColor(AppColors.textTertiary)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing) { value in
                            AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
                            AxisValueLabel {
                                if let val = value.as(Double.self) {
                                    Text(PriceUtils.formatPrice(val))
                                        .font(.caption2)
                                        .foregroundColor(AppColors.textTertiary)
                                }
                            }
                        }
                    }
                    .frame(height: 160)
                    .accessibilityLabel({
                        let values = prices.map { "\($0.0): \(PriceUtils.formatPrice($0.1)) 元" }.joined(separator: "，")
                        return "\(title)。\(values)"
                    }())
                    .accessibilityHint("顯示 \(prices.count) 筆價格資料的折線圖")
                }
            }
            .padding(16)
        }
    }

    // MARK: - 預測卡片（修復型別問題）
    private func predictionCard(_ pred: PricePrediction) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("AI 價格預測")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)

                let arrow = PriceUtils.trendArrow(pred.direction)
                let percentChangeText = String(format: "%.1f", abs(pred.changePercent))
                Text("預測價格: \(PriceUtils.formatPrice(pred.predictedPrice)) 元 \(arrow) (\(percentChangeText)%)")
                    .font(.callout)

                ProgressView(value: min(max(pred.confidence, 0), 100), total: 100) {
                    Text("信心度: \(Int(min(max(pred.confidence, 0), 100)))%")
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

    // MARK: - 區段錯誤提示
    private func sectionErrorView(icon: String, text: String) -> some View {
        GlassCard {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(AppColors.textTertiary)
                Text(text)
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(16)
        }
    }

    // MARK: - 載入資料
    private func loadDetail() {
        isLoading = true
        errorMessage = nil
        logger.log("載入產品詳情: \(cropName)", level: .info)

        Task {
            do {
                async let detailTask = ApiClient.shared.fetchProductDetail(cropName: cropName)
                async let predTask: (PricePrediction?, Bool) = {
                    do {
                        return (try await ApiClient.shared.fetchPrediction(cropName: cropName), false)
                    } catch {
                        logger.log("取得預測失敗: \(error.localizedDescription)", level: .warning)
                        return (nil, true)
                    }
                }()
                async let recipesTask: ([Recipe], Bool) = {
                    do {
                        return (try await ApiClient.shared.fetchRecipes(cropName: cropName), false)
                    } catch {
                        logger.log("取得食譜失敗: \(error.localizedDescription)", level: .warning)
                        return ([], true)
                    }
                }()

                let (d, (p, pFailed), (r, rFailed)) = await (try detailTask, predTask, recipesTask)

                await MainActor.run {
                    detail = d
                    prediction = p
                    predictionFailed = pFailed
                    recipes = r
                    recipesFailed = rFailed
                    isLoading = false
                    logger.log("產品詳情載入成功", level: .debug)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "載入失敗: \(error.localizedDescription)"
                    isLoading = false
                    logger.log("產品詳情載入失敗: \(error.localizedDescription)", level: .error)
                }
            }
        }
    }
}
