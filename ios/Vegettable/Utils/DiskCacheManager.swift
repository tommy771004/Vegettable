import Foundation

/// 磁碟快取管理器 — 2 層快取：記憶體 (10 分鐘) + 磁碟 (7 天)
class DiskCacheManager {
    static let shared = DiskCacheManager()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// 記憶體快取 (10 分鐘過期)
    private var memoryCache: [String: (data: Data, expiresAt: Date)] = [:]

    /// 磁碟快取過期時間 (7 天)
    private let diskCacheExpiration: TimeInterval = 7 * 24 * 3600

    /// 記憶體快取過期時間 (10 分鐘)
    private let memoryCacheExpiration: TimeInterval = 10 * 60

    private init() {
        // 初始化快取目錄
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("Vegettable", isDirectory: true)

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// 取得快取 (先檢查記憶體，再檢查磁碟)
    func getCached<T: Decodable>(key: String) -> T? {
        // 1. 檢查記憶體快取
        if let (data, expiresAt) = memoryCache[key], expiresAt > Date() {
            return try? decoder.decode(T.self, from: data)
        }

        // 2. 檢查磁碟快取
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        guard let fileData = try? Data(contentsOf: fileURL) else { return nil }

        // 檢查修改時間是否在 7 天內
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let modDate = attributes[.modificationDate] as? Date,
              Date().timeIntervalSince(modDate) < diskCacheExpiration else {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }

        // 解析並存入記憶體快取
        guard let decoded = try? decoder.decode(T.self, from: fileData) else { return nil }
        memoryCache[key] = (fileData, Date().addingTimeInterval(memoryCacheExpiration))
        return decoded
    }

    /// 設定快取 (同時存入記憶體和磁碟)
    func setCached<T: Encodable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else { return }

        // 存入記憶體快取
        memoryCache[key] = (data, Date().addingTimeInterval(memoryCacheExpiration))

        // 存入磁碟快取
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        try? data.write(to: fileURL)
    }

    /// 清除特定快取
    func clearCache(key: String) {
        memoryCache.removeValue(forKey: key)
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        try? fileManager.removeItem(at: fileURL)
    }

    /// 清除所有快取
    func clearAllCache() {
        memoryCache.removeAll()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// 清除過期磁碟快取 (可在背景定期執行)
    func clearExpiredCache() {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return
        }

        let now = Date()
        for fileURL in files {
            guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                  let modDate = attributes[.modificationDate] as? Date,
                  now.timeIntervalSince(modDate) > diskCacheExpiration else {
                continue
            }
            try? fileManager.removeItem(at: fileURL)
        }
    }
}

// MARK: - Hash 擴展
extension String {
    var md5Hash: String {
        // 簡單的雜湊實現 — 用於快取檔案名稱
        let input = self.data(using: .utf8) ?? Data()
        let bytes = [UInt8](input)

        var hash: UInt32 = 5381
        for byte in bytes {
            hash = ((hash << 5) &+ hash) &+ UInt32(byte)
        }

        return String(format: "%08x", hash)
    }
}
