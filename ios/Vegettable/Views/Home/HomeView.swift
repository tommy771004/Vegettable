import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var settings: SettingsManager
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var products: [ProductSummary] = []
    @State private var filteredProducts: [ProductSummary] = []
    @State private var selectedCategory: CropCategory = .all
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showOfflineMode = false
    @State private var loadTask: Task<Void, Never>?
    private let logger = LoggerManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [AppColors.background, AppColors.backgroundEnd],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 網路狀態提示
                    if !networkMonitor.isConnected {
                        HStack {
                            Image(systemName: "wifi.slash")
                            Text("離線模式 - 顯示快取資料")
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(Color.orange)
                        .font(.caption)
                    }

                    // 分類選擇
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CropCategory.allCases, id: \.rawValue) { cat in
                                CategoryChip(
                                    label: cat.label,
                                    isSelected: selectedCategory == cat,
                                    action: {
                                        selectedCategory = cat
                                        updateFilteredProducts()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)

                    // 產品列表
                    if isLoading && products.isEmpty {
                        SkeletonListView(count: 8)
                    } else if let error = errorMessage, products.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(AppColors.textTertiary)
                            Text(error)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                            Button("重試") {
                                loadProducts()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppColors.primary)
                        }
                        .padding()
                        Spacer()
                    } else if filteredProducts.isEmpty {
                        Spacer()
                        Text("沒有找到相關產品")
                            .foregroundColor(AppColors.textTertiary)
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredProducts) { product in
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
        .task { loadProducts() }
    }

    private func updateFilteredProducts() {
        if selectedCategory == .all {
            filteredProducts = products
        } else {
            filteredProducts = products.filter { p in
                p.category == selectedCategory.rawValue
            }
        }
        logger.log("篩選更新: \(selectedCategory.label) - \(filteredProducts.count) 項", level: .debug)
    }

    private func loadProducts() {
        // 如果離線且有快取，直接使用快取
        if !networkMonitor.isConnected {
            if let cached = settings.loadCachedProducts() {
                products = cached
                updateFilteredProducts()
                errorMessage = nil
                return
            } else {
                errorMessage = "網路連線不可用，且無快取資料"
                return
            }
        }

        isLoading = true
        errorMessage = nil
        logger.log("載入產品: 分類 = \(selectedCategory.label)", level: .info)

        // 取消上一個尚未完成的請求，避免競態條件
        loadTask?.cancel()
        let requestedCategory = selectedCategory
        loadTask = Task {
            do {
                let result = try await ApiClient.shared.fetchProducts(category: requestedCategory.apiValue)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    products = result
                    updateFilteredProducts()
                    isLoading = false
                    settings.cacheProducts(result)
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    isLoading = false
                    logger.log("載入失敗: \(error.localizedDescription)", level: .error)
                    errorMessage = "載入失敗: \(error.localizedDescription)"

                    // 嘗試使用快取
                    if let cached = settings.loadCachedProducts() {
                        products = cached
                        updateFilteredProducts()
                        errorMessage = "已載入快取資料"
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
        Button(action: {
            let g = UISelectionFeedbackGenerator()
            g.selectionChanged()
            action()
        }) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            AppColors.primary
                        } else {
                            AppColors.glassBg
                        }
                    }
                )
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : AppColors.textTertiary.opacity(0.2), lineWidth: 0.5)
                )
                .animation(.easeInOut(duration: 0.18), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
