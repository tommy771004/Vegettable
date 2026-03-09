import SwiftUI

struct SearchView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var keyword = ""
    @State private var results: [ProductSummary] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                VStack(spacing: 0) {
                    // Liquid Glass 搜尋欄
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textTertiary)
                            .font(.system(size: 16))
                            .accessibilityHidden(true)
                        TextField("搜尋蔬果名稱…", text: $keyword)
                            .font(.system(size: 15, design: .rounded))
                            .textFieldStyle(.plain)
                            .accessibilityLabel("搜尋蔬果名稱")
                            .onChange(of: keyword) { _ in debounceSearch() }

                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(AppColors.primary)
                        }
                    }
                    .padding(14)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.4))
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.white.opacity(0.5), lineWidth: 0.8)
                        }
                    )
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                    .padding(.horizontal, 14)

                    if !results.isEmpty {
                        Text("找到 \(results.count) 項結果")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                    }

                    if let error = errorMessage, results.isEmpty {
                        Spacer()
                        VStack(spacing: 14) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.system(size: 40))
                                .foregroundColor(AppColors.textTertiary)
                            Text(error)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                            Button("重試") { debounceSearch() }
                                .buttonStyle(.borderedProminent)
                                .tint(AppColors.primary)
                                .clipShape(Capsule())
                        }
                        Spacer()
                    } else if results.isEmpty && !keyword.trimmingCharacters(in: .whitespaces).isEmpty && !isSearching {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(AppColors.textTertiary.opacity(0.5))
                            Text("找不到「\(keyword)」的相關結果")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(AppColors.textTertiary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(results) { product in
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
                            .padding(.top, 8)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationTitle("搜尋")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func debounceSearch() {
        searchTask?.cancel()
        errorMessage = nil
        let kw = keyword.trimmingCharacters(in: .whitespaces)
        guard !kw.isEmpty else {
            results = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            do {
                let searchResults = try await ApiClient.shared.searchProducts(keyword: kw)
                await MainActor.run {
                    results = searchResults
                    isSearching = false
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        isSearching = false
                        errorMessage = "搜尋失敗: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}
