import Foundation

// MARK: - API 除錯工具
class APIDebugger {
    static let shared = APIDebugger()
    
    private let logger = LoggerManager.shared
    private var requestLog: [APIRequestLog] = []
    private let maxLogs = 100
    
    struct APIRequestLog: Codable {
        let timestamp: Date
        let method: String
        let url: String
        let statusCode: Int?
        let duration: TimeInterval
        let errorDescription: String?
        let requestSize: Int
        let responseSize: Int
    }
    
    private init() {}
    
    func logRequest(
        method: String,
        url: String,
        statusCode: Int? = nil,
        duration: TimeInterval,
        error: Error? = nil,
        requestSize: Int = 0,
        responseSize: Int = 0
    ) {
        let log = APIRequestLog(
            timestamp: Date(),
            method: method,
            url: url,
            statusCode: statusCode,
            duration: duration,
            errorDescription: error?.localizedDescription,
            requestSize: requestSize,
            responseSize: responseSize
        )
        
        requestLog.append(log)
        if requestLog.count > maxLogs {
            requestLog.removeFirst()
        }
        
        if ConfigManager.shared.enableDetailedLogging {
            logger.log(
                "[API] \(method) \(url) - 狀態: \(statusCode ?? -1) - 耗時: \(String(format: "%.2f", duration))s",
                level: error != nil ? .error : .debug
            )
        }
    }
    
    func getRequestLogs() -> [APIRequestLog] {
        return requestLog
    }
    
    func clearLogs() {
        requestLog.removeAll()
        logger.log("已清除 API 日誌", level: .debug)
    }
    
    func exportLogs() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        var result = "API 請求日誌記錄\n"
        result += "生成時間: \(dateFormatter.string(from: Date()))\n"
        result += String(repeating: "=", count: 80) + "\n\n"
        
        for log in requestLog {
            result += "時間: \(dateFormatter.string(from: log.timestamp))\n"
            result += "方法: \(log.method)\n"
            result += "URL: \(log.url)\n"
            result += "狀態碼: \(log.statusCode?.description ?? "N/A")\n"
            result += "耗時: \(String(format: "%.2f", log.duration))s\n"
            result += "請求大小: \(log.requestSize) bytes\n"
            result += "回應大小: \(log.responseSize) bytes\n"
            if let error = log.errorDescription {
                result += "錯誤: \(error)\n"
            }
            result += String(repeating: "-", count: 80) + "\n\n"
        }
        
        return result
    }
}
