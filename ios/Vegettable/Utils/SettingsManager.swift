import SwiftUI

class SettingsManager: ObservableObject {
    @AppStorage("priceUnit") var priceUnit: String = "kg"
    @AppStorage("showRetailPrice") var showRetailPrice: Bool = false
    @AppStorage("darkMode") var darkMode: String = "system"
    @AppStorage("language") var language: String = "zh-TW"
    @AppStorage("selectedMarket") var selectedMarket: String = ""

    @Published var favorites: Set<String> = [] {
        didSet {
            saveFavorites()
        }
    }

    // 產品快取
    @Published var cachedProducts: [ProductSummary] = []
    @Published var cacheTime: Date = .distantPast

    init() {
        loadFavorites()
    }

    func isFavorite(_ cropCode: String) -> Bool {
        favorites.contains(cropCode)
    }

    func toggleFavorite(_ cropCode: String) {
        if favorites.contains(cropCode) {
            favorites.remove(cropCode)
        } else {
            favorites.insert(cropCode)
        }
    }

    func displayPrice(_ price: Double) -> Double {
        var p = price
        if priceUnit == "catty" {
            p = PriceUtils.convertToCatty(p)
        }
        if showRetailPrice {
            p = PriceUtils.estimateRetail(p)
        }
        return p
    }

    var unitLabel: String {
        priceUnit == "catty" ? "元/台斤" : "元/公斤"
    }

    // MARK: - Persistence
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favorites), forKey: "favoritesList")
    }

    private func loadFavorites() {
        if let saved = UserDefaults.standard.array(forKey: "favoritesList") as? [String] {
            favorites = Set(saved)
        }
    }

    func cacheProducts(_ products: [ProductSummary]) {
        cachedProducts = products
        cacheTime = Date()
        if let data = try? JSONEncoder().encode(products) {
            UserDefaults.standard.set(data, forKey: "cachedProducts")
            UserDefaults.standard.set(Date(), forKey: "cacheTime")
        }
    }

    func loadCachedProducts() -> [ProductSummary]? {
        guard let data = UserDefaults.standard.data(forKey: "cachedProducts") else { return nil }
        return try? JSONDecoder().decode([ProductSummary].self, from: data)
    }

    var isCacheStale: Bool {
        let cacheTime = UserDefaults.standard.object(forKey: "cacheTime") as? Date ?? .distantPast
        return Date().timeIntervalSince(cacheTime) > 3600
    }
}
