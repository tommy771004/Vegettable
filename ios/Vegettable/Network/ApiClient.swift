import Foundation
import Network

// MARK: - API 端點設定
enum ApiEndpoints {
    static var baseURL: String {
        ConfigManager.shared.apiBaseURL
    }

    static let products = "/api/products"
    static let searchProducts = "/api/products/search"
    static let markets = "/api/markets"
    static let marketCompare = "/api/markets/compare"
    static let alerts = "/api/alerts"
    static let prediction = "/api/prediction"
    static let seasonal = "/api/prediction/seasonal"
    static let health = "/health"
}

// MARK: - API 客戶端
class ApiClient: ObservableObject {
    static let shared = ApiClient()
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger = LoggerManager.shared
    private let debugger = APIDebugger.shared
    private let cacheManager = CacheManager.shared

    // 重試設定
    private var maxRetries: Int { ConfigManager.shared.maxRetries }
    private let retryDelay: UInt64 = 1_000_000_000 // 1 秒

    // 錯誤計數（用於監測 API 健康狀態）
    @Published private(set) var consecutiveErrors = 0
    private let errorResetThreshold = 3600.0 // 1 小時

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = ConfigManager.shared.apiTimeout
        config.timeoutIntervalForResource = ConfigManager.shared.apiTimeout * 2
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
    }

    // MARK: - 通用 GET（帶重試、驗證和偵錯）
    private func get<T: Codable>(path: String, params: [String: String]? = nil, retry: Int = 0) async throws -> T {
        var urlString = ApiEndpoints.baseURL + path
        if let params = params, !params.isEmpty {
            let queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
            var components = URLComponents(string: urlString)!
            components.queryItems = queryItems
            urlString = components.url!.absoluteString
        }

        guard let url = URL(string: urlString) else {
            throw ApiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("VegetableApp/1.0", forHTTPHeaderField: "User-Agent")

        let startTime = Date()
        do {
            let (data, response) = try await session.data(for: request)
            let duration = Date().timeIntervalSince(startTime)

            guard let httpResponse = response as? HTTPURLResponse else {
                debugger.logRequest(method: "GET", url: path, duration: duration, error: ApiError.serverError)
                throw ApiError.serverError
            }

            debugger.logRequest(
                method: "GET",
                url: path,
                statusCode: httpResponse.statusCode,
                duration: duration,
                requestSize: 0,
                responseSize: data.count
            )

            // 驗證 HTTP 狀態碼
            switch httpResponse.statusCode {
            case 200:
                break
            case 400, 404:
                throw ApiError.clientError("請求無效或資源不存在")
            case 429:
                if retry < maxRetries {
                    logger.log("速率限制，進行重試 \(retry + 1)/\(maxRetries)", level: .warning)
                    try await Task.sleep(nanoseconds: retryDelay * UInt64(retry + 1))
                    return try await get(path: path, params: params, retry: retry + 1)
                }
                throw ApiError.rateLimited
            case 500...599:
                if retry < maxRetries {
                    logger.log("伺服器錯誤 (\(httpResponse.statusCode))，進行重試 \(retry + 1)/\(maxRetries)", level: .warning)
                    try await Task.sleep(nanoseconds: retryDelay * UInt64(retry + 1))
                    return try await get(path: path, params: params, retry: retry + 1)
                }
                throw ApiError.serverError
            default:
                throw ApiError.serverError
            }

            // 解析並驗證回應
            let apiResponse = try decoder.decode(ApiResponse<T>.self, from: data)

            guard apiResponse.success, let responseData = apiResponse.data else {
                throw ApiError.apiError(apiResponse.message ?? "資料取得失敗")
            }

            // 重置錯誤計數
            consecutiveErrors = 0
            logger.log("GET \(path) 成功", level: .debug)

            return responseData
        } catch {
            consecutiveErrors += 1
            let duration = Date().timeIntervalSince(startTime)
            debugger.logRequest(method: "GET", url: path, duration: duration, error: error)
            logger.log("GET \(path) 失敗: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    // MARK: - 通用 POST（帶重試、驗證和偵錯）
    private func post<T: Codable, B: Codable>(path: String, body: B, retry: Int = 0) async throws -> T {
        let urlString = ApiEndpoints.baseURL + path
        guard let url = URL(string: urlString) else { throw ApiError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("VegetableApp/1.0", forHTTPHeaderField: "User-Agent")
        
        let bodyData = try JSONEncoder().encode(body)
        request.httpBody = bodyData

        let startTime = Date()
        do {
            let (data, response) = try await session.data(for: request)
            let duration = Date().timeIntervalSince(startTime)

            guard let httpResponse = response as? HTTPURLResponse else {
                debugger.logRequest(method: "POST", url: path, duration: duration, error: ApiError.serverError)
                throw ApiError.serverError
            }

            debugger.logRequest(
                method: "POST",
                url: path,
                statusCode: httpResponse.statusCode,
                duration: duration,
                requestSize: bodyData.count,
                responseSize: data.count
            )

            switch httpResponse.statusCode {
            case 200, 201:
                break
            case 429:
                if retry < maxRetries {
                    logger.log("速率限制，進行重試 \(retry + 1)/\(maxRetries)", level: .warning)
                    try await Task.sleep(nanoseconds: retryDelay * UInt64(retry + 1))
                    return try await post(path: path, body: body, retry: retry + 1)
                }
                throw ApiError.rateLimited
            case 500...599:
                if retry < maxRetries {
                    logger.log("伺服器錯誤，進行重試 \(retry + 1)/\(maxRetries)", level: .warning)
                    try await Task.sleep(nanoseconds: retryDelay * UInt64(retry + 1))
                    return try await post(path: path, body: body, retry: retry + 1)
                }
                throw ApiError.serverError
            default:
                throw ApiError.serverError
            }

            let apiResponse = try decoder.decode(ApiResponse<T>.self, from: data)

            guard apiResponse.success, let responseData = apiResponse.data else {
                throw ApiError.apiError(apiResponse.message ?? "操作失敗")
            }

            consecutiveErrors = 0
            logger.log("POST \(path) 成功", level: .debug)

            return responseData
        } catch {
            consecutiveErrors += 1
            let duration = Date().timeIntervalSince(startTime)
            debugger.logRequest(method: "POST", url: path, duration: duration, error: error)
            logger.log("POST \(path) 失敗: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    // MARK: - 通用 DELETE（帶重試和偵錯）
    private func delete(path: String, retry: Int = 0) async throws {
        let urlString = ApiEndpoints.baseURL + path
        guard let url = URL(string: urlString) else { throw ApiError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("VegetableApp/1.0", forHTTPHeaderField: "User-Agent")

        let startTime = Date()
        do {
            let (_, response) = try await session.data(for: request)
            let duration = Date().timeIntervalSince(startTime)

            guard let httpResponse = response as? HTTPURLResponse else {
                debugger.logRequest(method: "DELETE", url: path, duration: duration, error: ApiError.serverError)
                throw ApiError.serverError
            }

            debugger.logRequest(method: "DELETE", url: path, statusCode: httpResponse.statusCode, duration: duration)

            switch httpResponse.statusCode {
            case 200, 204:
                break
            case 429:
                if retry < maxRetries {
                    try await Task.sleep(nanoseconds: retryDelay * UInt64(retry + 1))
                    return try await delete(path: path, retry: retry + 1)
                }
                throw ApiError.rateLimited
            case 500...599:
                if retry < maxRetries {
                    try await Task.sleep(nanoseconds: retryDelay * UInt64(retry + 1))
                    return try await delete(path: path, retry: retry + 1)
                }
                throw ApiError.serverError
            default:
                throw ApiError.serverError
            }

            logger.log("DELETE \(path) 成功", level: .debug)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            debugger.logRequest(method: "DELETE", url: path, duration: duration, error: error)
            logger.log("DELETE \(path) 失敗: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    // MARK: - 通用 PATCH（帶重試和偵錯）
    private func patch(path: String, retry: Int = 0) async throws {
        let urlString = ApiEndpoints.baseURL + path
        guard let url = URL(string: urlString) else { throw ApiError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("VegetableApp/1.0", forHTTPHeaderField: "User-Agent")

        let startTime = Date()
        do {
            let (_, response) = try await session.data(for: request)
            let duration = Date().timeIntervalSince(startTime)

            guard let httpResponse = response as? HTTPURLResponse else {
                debugger.logRequest(method: "PATCH", url: path, duration: duration, error: ApiError.serverError)
                throw ApiError.serverError
            }

            debugger.logRequest(method: "PATCH", url: path, statusCode: httpResponse.statusCode, duration: duration)

            switch httpResponse.statusCode {
            case 200:
                break
            case 429:
                if retry < maxRetries {
                    try await Task.sleep(nanoseconds: retryDelay * UInt64(retry + 1))
                    return try await patch(path: path, retry: retry + 1)
                }
                throw ApiError.rateLimited
            case 500...599:
                if retry < maxRetries {
                    try await Task.sleep(nanoseconds: retryDelay * UInt64(retry + 1))
                    return try await patch(path: path, retry: retry + 1)
                }
                throw ApiError.serverError
            default:
                throw ApiError.serverError
            }

            logger.log("PATCH \(path) 成功", level: .debug)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            debugger.logRequest(method: "PATCH", url: path, duration: duration, error: error)
            logger.log("PATCH \(path) 失敗: \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    // MARK: - Products API
    func fetchProducts(category: String? = nil) async throws -> [ProductSummary] {
        var params: [String: String] = [:]
        if let category = category, category != "all" {
            params["category"] = category
        }
        return try await get(path: ApiEndpoints.products, params: params)
    }

    func searchProducts(keyword: String) async throws -> [ProductSummary] {
        guard !keyword.isEmpty else { throw ApiError.invalidInput("搜尋關鍵字不能為空") }
        return try await get(path: ApiEndpoints.searchProducts, params: ["keyword": keyword])
    }

    func fetchProductDetail(cropName: String) async throws -> ProductDetail {
        guard !cropName.isEmpty else { throw ApiError.invalidInput("作物名稱不能為空") }
        let encoded = cropName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cropName
        return try await get(path: "\(ApiEndpoints.products)/\(encoded)")
    }

    // MARK: - Markets API
    func fetchMarkets() async throws -> [Market] {
        return try await get(path: ApiEndpoints.markets)
    }

    func fetchMarketPrices(marketName: String, cropName: String? = nil) async throws -> [MarketPrice] {
        guard !marketName.isEmpty else { throw ApiError.invalidInput("市場名稱不能為空") }
        let encoded = marketName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? marketName
        var params: [String: String] = [:]
        if let cropName = cropName { params["cropName"] = cropName }
        return try await get(path: "\(ApiEndpoints.markets)/\(encoded)/prices", params: params)
    }

    func compareMarketPrices(cropName: String, markets: [String]? = nil) async throws -> [MarketPrice] {
        guard !cropName.isEmpty else { throw ApiError.invalidInput("作物名稱不能為空") }
        let encoded = cropName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cropName
        var params: [String: String] = [:]
        if let markets = markets, !markets.isEmpty {
            params["markets"] = markets.joined(separator: ",")
        }
        return try await get(path: "\(ApiEndpoints.marketCompare)/\(encoded)", params: params)
    }

    // MARK: - Alerts API
    func fetchAlerts(deviceToken: String) async throws -> [PriceAlert] {
        guard !deviceToken.isEmpty else { throw ApiError.invalidInput("裝置令牌不能為空") }
        return try await get(path: ApiEndpoints.alerts, params: ["deviceToken": deviceToken])
    }

    func createAlert(request: CreateAlertRequest) async throws -> PriceAlert {
        return try await post(path: ApiEndpoints.alerts, body: request)
    }

    func deleteAlert(id: Int, deviceToken: String) async throws {
        guard !deviceToken.isEmpty else { throw ApiError.invalidInput("裝置令牌不能為空") }
        let encoded = deviceToken.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? deviceToken
        try await delete(path: "\(ApiEndpoints.alerts)/\(id)?deviceToken=\(encoded)")
    }

    func toggleAlert(id: Int, deviceToken: String) async throws {
        guard !deviceToken.isEmpty else { throw ApiError.invalidInput("裝置令牌不能為空") }
        let encoded = deviceToken.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? deviceToken
        try await patch(path: "\(ApiEndpoints.alerts)/\(id)/toggle?deviceToken=\(encoded)")
    }

    // MARK: - Prediction / Seasonal / Recipes API
    func fetchPrediction(cropName: String) async throws -> PricePrediction {
        guard !cropName.isEmpty else { throw ApiError.invalidInput("作物名稱不能為空") }
        let encoded = cropName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cropName
        return try await get(path: "\(ApiEndpoints.prediction)/\(encoded)")
    }

    func fetchSeasonalInfo(category: String? = nil) async throws -> [SeasonalInfo] {
        var params: [String: String] = [:]
        if let category = category { params["category"] = category }
        return try await get(path: ApiEndpoints.seasonal, params: params)
    }

    func fetchRecipes(cropName: String) async throws -> [Recipe] {
        guard !cropName.isEmpty else { throw ApiError.invalidInput("作物名稱不能為空") }
        let encoded = cropName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cropName
        return try await get(path: "\(ApiEndpoints.prediction)/\(encoded)/recipes")
    }

    // MARK: - Health
    func checkHealth() async -> Bool {
        guard let url = URL(string: "\(ApiEndpoints.baseURL)\(ApiEndpoints.health)") else { return false }
        do {
            let (_, response) = try await session.data(from: url)
            let isHealthy = (response as? HTTPURLResponse)?.statusCode == 200
            if isHealthy {
                consecutiveErrors = 0
            }
            return isHealthy
        } catch {
            logger.log("健康檢查失敗: \(error.localizedDescription)", level: .warning)
            return false
        }
    }
}

// MARK: - 錯誤類型（擴充）
enum ApiError: LocalizedError {
    case invalidURL
    case serverError
    case clientError(String)
    case apiError(String)
    case rateLimited
    case invalidInput(String)
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無效的 URL"
        case .serverError:
            return "伺服器暫時無法服務，請稍後重試"
        case .clientError(let msg):
            return "請求錯誤: \(msg)"
        case .apiError(let msg):
            return msg
        case .rateLimited:
            return "請求過於頻繁，請稍候再試"
        case .invalidInput(let msg):
            return "輸入無效: \(msg)"
        case .networkUnavailable:
            return "網路連線不可用"
        }
    }
}
