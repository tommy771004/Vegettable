import Foundation

// MARK: - 環境配置管理
class ConfigManager {
    static let shared = ConfigManager()
    
    private let logger = LoggerManager.shared
    
    enum Environment: String {
        case development = "DEV"
        case staging = "STAGING"
        case production = "PROD"
    }
    
    var currentEnvironment: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    var apiBaseURL: String {
        switch currentEnvironment {
        case .development:
            return "http://localhost:5180"
        case .staging:
            return "https://staging.vegettable.app"
        case .production:
            return "https://api.vegettable.app"
        }
    }
    
    var apiTimeout: TimeInterval {
        switch currentEnvironment {
        case .development:
            return 30
        case .staging:
            return 20
        case .production:
            return 15
        }
    }
    
    var maxRetries: Int {
        switch currentEnvironment {
        case .development:
            return 3
        case .staging:
            return 2
        case .production:
            return 1
        }
    }
    
    var enableDetailedLogging: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    private init() {
        logger.log("初始化配置管理器 - 環境: \(currentEnvironment.rawValue)", level: .info)
    }
}
