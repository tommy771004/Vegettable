import SwiftUI

struct SearchView: View {
    @EnvironmentObject var settings: SettingsManager
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var keyword = ""
    @State private var results: [ProductSummary] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var errorMessage: String?
    @State private var searchHistory: [String] = []
    private let logger = LoggerManager.shared
    private let debugLogger = DebugLogger.shared

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [AppColors.background, AppColors.backgroundEnd],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 網路狀態
                    if !networkMonitor.isConnected {
                        HStack {
                            Image(systemName: "wifi.slash")
                            Text("離線模式 - 無法搜尋")
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(AppColors.warning.opacity(0.1))
                        .foregroundColor(AppColors.warning)
                        .font(.caption)
                    }

                    // 搜尋欄
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textTertiary)
                        TextField("搜尋蔬果名稱…", text: $keyword)
                            .textFieldStyle(.plain)
                            .disabled(!networkMonitor.isConnected)
                            .onChange(of: keyword) { _ in debounceSearch() }
                            .accessibilityLabel("搜尋蔬果名稱")
                        if !keyword.isEmpty {
                            Button(action: { keyword = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppColors.textTertiary)
                            }
                            .accessibilityLabel("清除搜尋")
                        }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    if !results.isEmpty {
                        Text("找到 \(results.count) 項結果")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    } else if isSearching {
                        Spacer()
                        ProgressView("搜尋中…")
                            .accessibilityLabel("正在搜尋")
                        Spacer()
                    } else if let error = errorMessage {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(AppColors.error)
                            Text(error)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                            Button(action: { retrySearch() }) {
                                Text("重試")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                    .background(AppColors.primary)
                                    .cornerRadius(8)
                            }
                            .accessibilityLabel("重試搜尋")
                        }
                        .padding()
                        Spacer()
                    } else if !keyword.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(AppColors.textTertiary)
                            Text("未找到結果")
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                    } else if !searchHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("搜尋歷史")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Button(action: clearSearchHistory) {
                                    Text("清除")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textTertiary)
                                }
                                .accessibilityLabel("清除搜尋歷史")
                            }
                            .padding(.horizontal)

                            ForEach(searchHistory.prefix(5), id: \.self) { term in
                                Button(action: { keyword = term; debounceSearch() }) {
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundColor(AppColors.textTertiary)
                                        Text(term)
                                            .foregroundColor(AppColors.textPrimary)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(.top, 12)
                        Spacer()
                    }

                    if !results.isEmpty {
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
            }
            .navigationTitle("搜尋")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { loadSearchHistory() }
        }
    }

    private func debounceSearch() {
        searchTask?.cancel()
        errorMessage = nil
        let kw = keyword.trimmingCharacters(in: .whitespaces)
        guard !kw.isEmpty else {
            results = []
            return
        }

        guard networkMonitor.isConnected else {
            errorMessage = "網路連線不可用"
            debugLogger.warning("搜尋失敗: 網路未連接")
            return
        }

        isSearching = true
        logger.log("搜尋: \(kw)", level: .debug)
        debugLogger.debug("開始搜尋: \(kw)")

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms 去抖動
            guard !Task.isCancelled else { return }

            do {
                let searchResults = try await ApiClient.shared.searchProducts(keyword: kw)
                await MainActor.run {
                    results = searchResults
                    isSearching = false
                    addToSearchHistory(kw)
                    logger.log("搜尋完成: 找到 \(searchResults.count) 項結果", level: .debug)
                    debugLogger.info("搜尋完成: 找到 \(searchResults.count) 項結果")
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                    errorMessage = "搜尋失敗: \(error.localizedDescription)"
                    logger.log("搜尋失敗: \(error.localizedDescription)", level: .error)
                    debugLogger.error("搜尋失敗: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func retrySearch() {
        errorMessage = nil
        debounceSearch()
    }
    
    private func addToSearchHistory(_ term: String) {
        var history = searchHistory.filter { $0 != term }
        history.insert(term, at: 0)
        if history.count > 5 { history = Array(history.prefix(5)) }
        searchHistory = history
        UserDefaults.standard.set(history, forKey: "searchHistory")
    }

    private func clearSearchHistory() {
        searchHistory = []
        UserDefaults.standard.removeObject(forKey: "searchHistory")
    }

    private func loadSearchHistory() {
        searchHistory = UserDefaults.standard.stringArray(forKey: "searchHistory") ?? []
    }
}

#Preview {
    SearchView()
        .environmentObject(SettingsManager())
}
