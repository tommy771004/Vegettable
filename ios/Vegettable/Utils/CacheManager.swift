import Foundation

// MARK: - 進階快取管理系統
class CacheManager {
    static let shared = CacheManager()
    
    private let logger = LoggerManager.shared
    private var memoryCache: [String: CacheEntry] = [:]
    
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
        memoryCache[key] = CacheEntry(
            data: data,
            createdAt: Date(),
            expirySeconds: expirySeconds
        )
        logger.log("快取已設定: \(key) (有效期: \(Int(expirySeconds))s)", level: .debug)
    }
    
    func getCacheData(forKey key: String) -> Data? {
        guard let entry = memoryCache[key] else {
            return nil
        }
        
        if entry.isExpired {
            memoryCache.removeValue(forKey: key)
            logger.log("快取已過期: \(key)", level: .debug)
            return nil
        }
        
        logger.log("快取命中: \(key)", level: .debug)
        return entry.data
    }
    
    func removeCacheData(forKey key: String) {
        memoryCache.removeValue(forKey: key)
        logger.log("快取已移除: \(key)", level: .debug)
    }
    
    func clearAllCache() {
        memoryCache.removeAll()
        logger.log("所有快取已清除", level: .debug)
    }
    
    // MARK: - 磁碟快取
    func saveToDisk<T: Codable>(_ object: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(object)
            let fileURL = getDocumentsDirectory().appendingPathComponent("\(key).cache")
            try data.write(to: fileURL, options: .atomic)
            logger.log("對象已保存到磁碟: \(key)", level: .debug)
        } catch {
            logger.log("保存到磁碟失敗 \(key): \(error.localizedDescription)", level: .error)
        }
    }
    
    func loadFromDisk<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        do {
            let fileURL = getDocumentsDirectory().appendingPathComponent("\(key).cache")
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
        do {
            let fileURL = getDocumentsDirectory().appendingPathComponent("\(key).cache")
            try FileManager.default.removeItem(at: fileURL)
            logger.log("磁碟快取已移除: \(key)", level: .debug)
        } catch {
            logger.log("移除磁碟快取失敗: \(error.localizedDescription)", level: .debug)
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
