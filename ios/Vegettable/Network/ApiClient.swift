import Foundation

// MARK: - API 端點設定
enum ApiEndpoints {
    #if DEBUG
    static let baseURL = "http://localhost:5180"
    #else
    // ⚠️ 正式發佈前請替換為真實 API URL（或透過 Info.plist / xcconfig 注入）
    static let baseURL = "https://api.vegettable.app"
    #endif

    // API 版本（配合後端 API Versioning）
    private static let v1 = "/api"  // 目前後端 AssumeDefaultVersionWhenUnspecified = true，路徑不變

    static let products = "\(v1)/products"
    static let searchProducts = "\(v1)/products/search"
    static let markets = "\(v1)/markets"
    static let marketCompare = "\(v1)/markets/compare"
    static let alerts = "\(v1)/alerts"
    static let prediction = "\(v1)/prediction"
    static let seasonal = "\(v1)/prediction/seasonal"
    static let health = "/health"
}

// MARK: - API 客戶端
class ApiClient {
    static let shared = ApiClient()
    private let session: URLSession
    private let decoder: JSONDecoder

    /// 重試設定
    private let maxRetries = 3
    private let baseDelay: TimeInterval = 1.0

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
    }

    // MARK: - 指數退避重試
    private func withRetry<T>(maxAttempts: Int = 3, operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        for attempt in 0..<maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                if error is ApiError { throw error }
                if attempt < maxAttempts - 1 {
                    let delay = baseDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        throw lastError ?? ApiError.serverError
    }

    // MARK: - 通用 GET（含重試）
    private func get<T: Codable>(path: String, params: [String: String]? = nil) async throws -> T {
        try await withRetry { [self] in
            let urlString = ApiEndpoints.baseURL + path

            guard var components = URLComponents(string: urlString) else {
                throw ApiError.invalidURL
            }

            if let params = params, !params.isEmpty {
                components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
            }

            guard let url = components.url else {
                throw ApiError.invalidURL
            }

            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                if statusCode == 404 {
                    throw ApiError.notFound
                }
                throw ApiError.serverError
            }

            let apiResponse = try decoder.decode(ApiResponse<T>.self, from: data)

            guard apiResponse.success, let responseData = apiResponse.data else {
                throw ApiError.apiError(apiResponse.message ?? "資料取得失敗")
            }

            return responseData
        }
    }

    // MARK: - 通用 POST（含重試）
    private func post<T: Codable, B: Codable>(path: String, body: B) async throws -> T {
        try await withRetry { [self] in
            let urlString = ApiEndpoints.baseURL + path
            guard let url = URL(string: urlString) else { throw ApiError.invalidURL }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                if statusCode == 404 {
                    throw ApiError.notFound
                }
                throw ApiError.serverError
            }

            let apiResponse = try decoder.decode(ApiResponse<T>.self, from: data)

            guard apiResponse.success, let responseData = apiResponse.data else {
                throw ApiError.apiError(apiResponse.message ?? "操作失敗")
            }

            return responseData
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
        return try await get(path: ApiEndpoints.searchProducts, params: ["keyword": keyword])
    }

    func fetchProductDetail(cropName: String) async throws -> ProductDetail {
        let encoded = cropName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cropName
        return try await get(path: "\(ApiEndpoints.products)/\(encoded)")
    }

    // MARK: - Markets API
    func fetchMarkets() async throws -> [Market] {
        return try await get(path: ApiEndpoints.markets)
    }

    func fetchMarketPrices(marketName: String, cropName: String? = nil) async throws -> [MarketPrice] {
        let encoded = marketName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? marketName
        var params: [String: String] = [:]
        if let cropName = cropName { params["cropName"] = cropName }
        return try await get(path: "\(ApiEndpoints.markets)/\(encoded)/prices", params: params)
    }

    func compareMarketPrices(cropName: String, markets: [String]? = nil) async throws -> [MarketPrice] {
        let encoded = cropName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cropName
        var params: [String: String] = [:]
        if let markets = markets, !markets.isEmpty {
            params["markets"] = markets.joined(separator: ",")
        }
        return try await get(path: "\(ApiEndpoints.marketCompare)/\(encoded)", params: params)
    }

    // MARK: - Alerts API
    func fetchAlerts(deviceToken: String) async throws -> [PriceAlert] {
        return try await get(path: ApiEndpoints.alerts, params: ["deviceToken": deviceToken])
    }

    func createAlert(request: CreateAlertRequest) async throws -> PriceAlert {
        return try await post(path: ApiEndpoints.alerts, body: request)
    }

    func deleteAlert(id: Int, deviceToken: String) async throws {
        let encoded = deviceToken.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? deviceToken
        let urlString = "\(ApiEndpoints.baseURL)\(ApiEndpoints.alerts)/\(id)?deviceToken=\(encoded)"
        guard let url = URL(string: urlString) else { throw ApiError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ApiError.serverError
        }
    }

    func toggleAlert(id: Int, deviceToken: String) async throws {
        let encoded = deviceToken.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? deviceToken
        let urlString = "\(ApiEndpoints.baseURL)\(ApiEndpoints.alerts)/\(id)/toggle?deviceToken=\(encoded)"
        guard let url = URL(string: urlString) else { throw ApiError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ApiError.serverError
        }
    }

    // MARK: - Prediction / Seasonal / Recipes API
    func fetchPrediction(cropName: String) async throws -> PricePrediction {
        let encoded = cropName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cropName
        return try await get(path: "\(ApiEndpoints.prediction)/\(encoded)")
    }

    func fetchSeasonalInfo(category: String? = nil) async throws -> [SeasonalInfo] {
        var params: [String: String] = [:]
        if let category = category { params["category"] = category }
        return try await get(path: ApiEndpoints.seasonal, params: params)
    }

    func fetchRecipes(cropName: String) async throws -> [Recipe] {
        let encoded = cropName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cropName
        return try await get(path: "\(ApiEndpoints.prediction)/\(encoded)/recipes")
    }

    // MARK: - Health
    func checkHealth() async -> Bool {
        guard let url = URL(string: "\(ApiEndpoints.baseURL)\(ApiEndpoints.health)") else { return false }
        do {
            let (_, response) = try await session.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}

// MARK: - 錯誤類型
enum ApiError: LocalizedError {
    case invalidURL
    case serverError
    case notFound
    case apiError(String)
    case offline

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無效的 URL"
        case .serverError: return "伺服器錯誤"
        case .notFound: return "找不到指定的資源"
        case .apiError(let msg): return msg
        case .offline: return "目前處於離線狀態"
        }
    }
}
