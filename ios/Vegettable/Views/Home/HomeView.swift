import SwiftUI

struct HomeView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var products: [ProductSummary] = []
    @State private var selectedCategory: CropCategory = .all
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [AppColors.background, AppColors.backgroundEnd],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 分類選擇
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CropCategory.allCases, id: \.rawValue) { cat in
                                CategoryChip(
                                    label: cat.label,
                                    isSelected: selectedCategory == cat,
                                    action: {
                                        selectedCategory = cat
                                        loadProducts()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)

                    // 產品列表
                    if isLoading && products.isEmpty {
                        Spacer()
                        ProgressView("載入中…")
                        Spacer()
                    } else if let error = errorMessage, products.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Text(error)
                                .foregroundColor(AppColors.textSecondary)
                            Button("重試") { loadProducts() }
                                .buttonStyle(.borderedProminent)
                                .tint(AppColors.primary)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(products) { product in
                                NavigationLink(destination: DetailView(cropName: product.cropName, cropCode: product.cropCode)) {
                                    ProductRow(
                                        product: product,
                                        isFavorite: settings.isFavorite(product.cropCode),
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
                        .refreshable { loadProducts() }
                    }
                }
            }
            .navigationTitle("菜價查詢")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { loadProducts() }
    }

    private func loadProducts() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await ApiClient.shared.fetchProducts(category: selectedCategory.apiValue)
                await MainActor.run {
                    products = result
                    isLoading = false
                    settings.cacheProducts(result)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "載入失敗: \(error.localizedDescription)"
                    // 使用快取
                    if let cached = settings.loadCachedProducts() {
                        products = cached
                        errorMessage = nil
                    }
                }
            }
        }
    }
}

struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.primary : AppColors.glassBg)
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .clipShape(Capsule())
        }
    }
}
