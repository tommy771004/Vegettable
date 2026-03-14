import SwiftUI

class SettingsManager: ObservableObject {
    @AppStorage("priceUnit") var priceUnit: String = "kg"
    @AppStorage("showRetailPrice") var showRetailPrice: Bool = false
    @AppStorage("language") var language: String = "zh-TW"
    @AppStorage("selectedMarket") var selectedMarket: String = ""
    @AppStorage("cacheExpiryMinutes") var cacheExpiryMinutes: Int = 60
    @AppStorage("autoUpdate") var autoUpdate: Bool = true

    // Backed by AppStorage("darkMode") for persistence
    @AppStorage("darkMode") private var _darkMode: String = "system"
    @Published var preferredColorScheme: ColorScheme? = nil {
        didSet {
            let newValue: String
            switch preferredColorScheme {
            case .dark: newValue = "dark"
            case .light: newValue = "light"
            default: newValue = "system"
            }
            if _darkMode != newValue { _darkMode = newValue }
        }
    }

    @Published var favorites: Set<String> = [] {
        didSet {
            saveFavorites()
        }
    }

    // 產品快取
    @Published var cachedProducts: [ProductSummary] = []
    @Published var cacheTime: Date = .distantPast

    private let logger = LoggerManager.shared
    private let cacheManager = CacheManager.shared

    init() {
        switch _darkMode {
        case "dark": preferredColorScheme = .dark
        case "light": preferredColorScheme = .light
        default: preferredColorScheme = nil
        }
        loadFavorites()
        loadCacheMetadata()
    }

    func isFavorite(_ cropCode: String) -> Bool {
        favorites.contains(cropCode)
    }

    func toggleFavorite(_ cropCode: String) {
        if favorites.contains(cropCode) {
            favorites.remove(cropCode)
            logger.log("移除收藏: \(cropCode)", level: .debug)
        } else {
            favorites.insert(cropCode)
            logger.log("新增收藏: \(cropCode)", level: .debug)
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
        do {
            cachedProducts = products
            cacheTime = Date()
            if let data = try? JSONEncoder().encode(products) {
                // 同時儲存到磁碟和記憶體
                cacheManager.setCacheData(data, forKey: "products", expirySeconds: TimeInterval(cacheExpiryMinutes * 60))
                cacheManager.saveToDisk(products, forKey: "products")
                UserDefaults.standard.set(data, forKey: "cachedProducts")
                UserDefaults.standard.set(cacheTime, forKey: "cacheTime")
                logger.log("快取 \(products.count) 個產品", level: .debug)
            }
        } catch {
            logger.log("快取產品失敗: \(error.localizedDescription)", level: .error)
        }
    }

    func loadCachedProducts() -> [ProductSummary]? {
        // 優先從磁碟載入
        if let diskProducts: [ProductSummary] = cacheManager.loadFromDisk([ProductSummary].self, forKey: "products") {
            if !isCacheStale {
                logger.log("從磁碟載入快取 \(diskProducts.count) 個產品", level: .debug)
                return diskProducts
            }
        }
        
        // 次優先從 UserDefaults 載入
        guard let data = UserDefaults.standard.data(forKey: "cachedProducts") else { return nil }
        guard !isCacheStale else {
            logger.log("快取已過期", level: .debug)
            clearCache()
            return nil
        }
        do {
            let products = try JSONDecoder().decode([ProductSummary].self, from: data)
            logger.log("載入快取 \(products.count) 個產品", level: .debug)
            return products
        } catch {
            logger.log("解碼快取失敗: \(error.localizedDescription)", level: .error)
            clearCache()
            return nil
        }
    }

    var isCacheStale: Bool {
        let cacheTime = UserDefaults.standard.object(forKey: "cacheTime") as? Date ?? .distantPast
        let expirySeconds = TimeInterval(cacheExpiryMinutes * 60)
        return Date().timeIntervalSince(cacheTime) > expirySeconds
    }

    func clearCache() {
        UserDefaults.standard.removeObject(forKey: "cachedProducts")
        UserDefaults.standard.removeObject(forKey: "cacheTime")
        cacheManager.removeFromDisk(forKey: "products")
        cacheManager.removeCacheData(forKey: "products")
        cachedProducts = []
        cacheTime = .distantPast
        logger.log("清除快取", level: .debug)
    }

    private func loadCacheMetadata() {
        if let time = UserDefaults.standard.object(forKey: "cacheTime") as? Date {
            cacheTime = time
        }
    }
}
