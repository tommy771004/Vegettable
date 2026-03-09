import SwiftUI

struct HomeView: View {
    @EnvironmentObject var settings: SettingsManager
    @ObservedObject private var network = NetworkMonitor.shared
    @State private var products: [ProductSummary] = []
    @State private var selectedCategory: CropCategory = .all
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                // Liquid Glass 背景
                LiquidGlassBackground()

                VStack(spacing: 0) {
                    // 離線橫幅
                    if !network.isConnected {
                        OfflineBanner()
                    }

                    // 分類選擇 — 膠囊晶片
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CropCategory.allCases, id: \.rawValue) { cat in
                                LiquidChip(
                                    label: cat.label,
                                    isSelected: selectedCategory == cat,
                                    action: {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedCategory = cat
                                        }
                                        loadProducts()
                                    }
                                )
                                .accessibilityLabel("分類：\(cat.label)")
                                .accessibilityAddTraits(selectedCategory == cat ? .isSelected : [])
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 10)

                    // 產品列表
                    if isLoading && products.isEmpty {
                        SkeletonListView()
                    } else if let error = errorMessage, products.isEmpty {
                        Spacer()
                        VStack(spacing: 14) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.system(size: 40))
                                .foregroundColor(AppColors.textTertiary)
                            Text(error)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                            Button("重試") { loadProducts() }
                                .buttonStyle(.borderedProminent)
                                .tint(AppColors.primary)
                                .clipShape(Capsule())
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
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
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.bottom, 100) // 為浮動 Tab Bar 留空間
                        }
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
                    if let cached = settings.loadCachedProducts() {
                        products = cached
                        errorMessage = nil
                    }
                }
            }
        }
    }
}

// MARK: - Liquid Glass 背景
struct LiquidGlassBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.background, AppColors.backgroundEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 柔和光暈裝飾
            Circle()
                .fill(AppColors.primary.opacity(0.06))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -200)

            Circle()
                .fill(Color.blue.opacity(0.04))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: 120, y: 150)
        }
    }
}

// MARK: - Liquid Glass 膠囊晶片
struct LiquidChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .rounded))
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .background(
                    ZStack {
                        if isSelected {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.primary, AppColors.primaryLight],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: AppColors.primary.opacity(0.3), radius: 8, y: 2)
                        } else {
                            Capsule()
                                .fill(.ultraThinMaterial)
                            Capsule()
                                .fill(Color.white.opacity(0.4))
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.5), lineWidth: 0.8)
                        }
                    }
                )
        }
    }
}
