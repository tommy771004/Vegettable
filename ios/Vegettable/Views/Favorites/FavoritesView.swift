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
                LinearGradient(colors: [AppColors.background, AppColors.backgroundEnd],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView("載入中…")
                } else if favoriteProducts.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.textTertiary)
                        Text("尚未收藏任何產品")
                            .foregroundColor(AppColors.textSecondary)
                        Text("點擊 ♡ 可加入收藏")
                            .font(.caption)
                            .foregroundColor(AppColors.textTertiary)
                    }
                } else {
                    List {
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
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("收藏 (\(settings.favorites.count))")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { loadProducts() }
    }

    private func loadProducts() {
        // 先嘗試快取
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
