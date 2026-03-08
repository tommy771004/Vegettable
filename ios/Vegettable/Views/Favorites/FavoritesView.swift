import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var allProducts: [ProductSummary] = []
    @State private var isLoading = false

    var favoriteProducts: [ProductSummary] {
        allProducts.filter { settings.isFavorite($0.cropCode) }
    }

    var body: some View {
        NavigationStack {
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
                } else if favoriteProducts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.textTertiary.opacity(0.6), AppColors.textTertiary],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        Text("尚未收藏任何產品")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                        Text("點擊 ♡ 可加入收藏")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(AppColors.textTertiary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(favoriteProducts) { product in
                                NavigationLink(destination: DetailView(cropName: product.cropName, cropCode: product.cropCode)) {
                                    ProductRow(
                                        product: product,
                                        isFavorite: true,
                                        priceUnit: settings.priceUnit,
                                        showRetail: settings.showRetailPrice,
                                        onFavorite: { settings.toggleFavorite(product.cropCode) }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("收藏 (\(settings.favorites.count))")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { loadProducts() }
    }

    private func loadProducts() {
        if let cached = settings.loadCachedProducts() {
            allProducts = cached
            return
        }

        isLoading = true
        Task {
            do {
                let products = try await ApiClient.shared.fetchProducts()
                await MainActor.run {
                    allProducts = products
                    isLoading = false
                }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }
}
