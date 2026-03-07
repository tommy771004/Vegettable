import SwiftUI

struct SearchView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var keyword = ""
    @State private var results: [ProductSummary] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [AppColors.background, AppColors.backgroundEnd],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 搜尋欄
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textTertiary)
                        TextField("搜尋蔬果名稱…", text: $keyword)
                            .textFieldStyle(.plain)
                            .onChange(of: keyword) { _ in debounceSearch() }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    if !results.isEmpty {
                        Text("找到 \(results.count) 項結果")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }

                    List {
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
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("搜尋")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func debounceSearch() {
        searchTask?.cancel()
        let kw = keyword.trimmingCharacters(in: .whitespaces)
        guard !kw.isEmpty else {
            results = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            guard !Task.isCancelled else { return }

            do {
                let searchResults = try await ApiClient.shared.searchProducts(keyword: kw)
                await MainActor.run {
                    results = searchResults
                }
            } catch {
                // 靜默失敗
            }
        }
    }
}
