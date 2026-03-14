import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 2)
    }
}

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
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.cropName)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)

                if !product.aliases.isEmpty {
                    Text(product.aliases.joined(separator: "、"))
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                }

                Text(PriceUtils.priceLevelLabel(product.priceLevel))
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .foregroundColor(PriceUtils.priceLevelColor(product.priceLevel))
                    .background(PriceUtils.priceLevelBgColor(product.priceLevel))
                    .clipShape(Capsule())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text(PriceUtils.formatPrice(displayPrice))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(PriceUtils.priceLevelColor(product.priceLevel))

                    Text(PriceUtils.trendArrow(product.trend))
                        .font(.body)
                        .foregroundColor(PriceUtils.trendColor(product.trend))
                }

                Text(priceUnit == "catty" ? "元/台斤" : "元/公斤")
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)

                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .gray)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}
