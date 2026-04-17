import Foundation

// MARK: - 進階快取管理系統（執行緒安全）
class CacheManager {
    static let shared = CacheManager()

    private let logger = LoggerManager.shared
    private var memoryCache: [String: CacheEntry] = [:]
    private let queue = DispatchQueue(label: "com.vegettable.cachemanager",
                                      attributes: .concurrent)

    struct CacheEntry {
        let data: Data
        let createdAt: Date
        let expirySeconds: TimeInterval

        var isExpired: Bool {
            Date().timeIntervalSince(createdAt) > expirySeconds
        }
    }

    private init() {}

    // MARK: - 記憶體快取
    func setCacheData(_ data: Data, forKey key: String, expirySeconds: TimeInterval = 3600) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.memoryCache[key] = CacheEntry(
                data: data,
                createdAt: Date(),
                expirySeconds: expirySeconds
            )
            self.logger.log("快取已設定: \(key) (有效期: \(Int(expirySeconds))s)", level: .debug)
        }
    }

    func getCacheData(forKey key: String) -> Data? {
        queue.sync {
            guard let entry = memoryCache[key] else { return nil }
            if entry.isExpired {
                queue.async(flags: .barrier) { [weak self] in
                    self?.memoryCache.removeValue(forKey: key)
                    self?.logger.log("快取已過期: \(key)", level: .debug)
                }
                return nil
            }
            logger.log("快取命中: \(key)", level: .debug)
            return entry.data
        }
    }

    func removeCacheData(forKey key: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.memoryCache.removeValue(forKey: key)
            self?.logger.log("快取已移除: \(key)", level: .debug)
        }
    }

    func clearAllCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.memoryCache.removeAll()
            self?.logger.log("所有快取已清除", level: .debug)
        }
    }

    // MARK: - 磁碟快取
    func saveToDisk<T: Codable>(_ object: T, forKey key: String) {
        guard let fileURL = cacheFileURL(forKey: key) else {
            logger.log("保存到磁碟失敗 \(key): 無法取得快取目錄", level: .error)
            return
        }
        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: fileURL, options: .atomic)
            logger.log("對象已保存到磁碟: \(key)", level: .debug)
        } catch {
            logger.log("保存到磁碟失敗 \(key): \(error.localizedDescription)", level: .error)
        }
    }

    func loadFromDisk<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let fileURL = cacheFileURL(forKey: key) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let object = try JSONDecoder().decode(T.self, from: data)
            logger.log("對象已從磁碟載入: \(key)", level: .debug)
            return object
        } catch {
            logger.log("從磁碟載入失敗 \(key): \(error.localizedDescription)", level: .debug)
            return nil
        }
    }

    func removeFromDisk(forKey key: String) {
        guard let fileURL = cacheFileURL(forKey: key) else { return }
        do {
            try FileManager.default.removeItem(at: fileURL)
            logger.log("磁碟快取已移除: \(key)", level: .debug)
        } catch {
            logger.log("移除磁碟快取失敗: \(error.localizedDescription)", level: .debug)
        }
    }

    /// 取得快取檔案 URL；改用 caches 目錄並安全展開 Optional 以避免 index-out-of-bounds。
    private func cacheFileURL(forKey key: String) -> URL? {
        let fm = FileManager.default
        let base = fm.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first
        let sanitized = key.replacingOccurrences(of: "/", with: "_")
        return base?.appendingPathComponent("\(sanitized).cache")
    }
}
