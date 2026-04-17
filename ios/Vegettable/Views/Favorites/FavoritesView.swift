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

                if isLoading && allProducts.isEmpty {
                    SkeletonListView(count: 6)
                } else if favoriteProducts.isEmpty {
                    EmptyFavoritesView()
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

private struct EmptyFavoritesView: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 56))
                .foregroundColor(AppColors.textTertiary.opacity(0.6))
                .scaleEffect(pulse ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)
            Text("尚未收藏任何產品")
                .font(.headline)
                .foregroundColor(AppColors.textSecondary)
            Text("在產品列表中點擊 ♡ 即可加入收藏")
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .onAppear { pulse = true }
    }
}
