import SwiftUI

// MARK: - Liquid Glass 卡片 (iOS 26 風格)
struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.ultraThinMaterial)

                    // 玻璃高光
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // 邊框折射光感
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.7),
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.06), radius: 16, y: 4)
            .shadow(color: .black.opacity(0.02), radius: 4, y: 1)
    }
}

// MARK: - Liquid Glass 產品列
struct ProductRow: View {
    let product: ProductSummary
    let isFavorite: Bool
    let priceUnit: String
    let showRetail: Bool
    let onFavorite: () -> Void

    var displayPrice: Double {
        var p = product.avgPrice
        if priceUnit == "catty" { p = PriceUtils.convertToCatty(p) }
        if showRetail { p = PriceUtils.estimateRetail(p) }
        return p
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(product.cropName)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)

                if !product.aliases.isEmpty {
                    Text(product.aliases.joined(separator: "、"))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(AppColors.textTertiary)
                }

                Text(PriceUtils.priceLevelLabel(product.priceLevel))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .foregroundColor(PriceUtils.priceLevelColor(product.priceLevel))
                    .background(
                        Capsule()
                            .fill(PriceUtils.priceLevelBgColor(product.priceLevel))
                            .overlay(
                                Capsule()
                                    .strokeBorder(PriceUtils.priceLevelColor(product.priceLevel).opacity(0.2), lineWidth: 0.5)
                            )
                    )
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                HStack(spacing: 4) {
                    Text(PriceUtils.formatPrice(displayPrice))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(PriceUtils.priceLevelColor(product.priceLevel))

                    Text(PriceUtils.trendArrow(product.trend))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(PriceUtils.trendColor(product.trend))
                }

                Text(priceUnit == "catty" ? "元/台斤" : "元/公斤")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(AppColors.textTertiary)

                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(isFavorite ? .pink : AppColors.textTertiary.opacity(0.6))
                }
                .accessibilityLabel(isFavorite ? "取消收藏" : "加入收藏")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(product.cropName)，價格 \(PriceUtils.formatPrice(displayPrice)) 元，\(PriceUtils.priceLevelLabel(product.priceLevel))")
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.45), Color.white.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.white.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 3)
    }
}
