import Foundation

// MARK: - API 端點設定
enum ApiEndpoints {
    #if DEBUG
    static let baseURL = "http://localhost:5180"
    #else
    static let baseURL = "https://your-production-api.com"
    #endif

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
class ApiClient {
    static let shared = ApiClient()
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
    }

    // MARK: - 通用 GET
    private func get<T: Codable>(path: String, params: [String: String]? = nil) async throws -> T {
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

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ApiError.serverError
        }

        let apiResponse = try decoder.decode(ApiResponse<T>.self, from: data)

        guard apiResponse.success, let responseData = apiResponse.data else {
            throw ApiError.apiError(apiResponse.message ?? "資料取得失敗")
        }

        return responseData
    }

    // MARK: - 通用 POST
    private func post<T: Codable, B: Codable>(path: String, body: B) async throws -> T {
        let urlString = ApiEndpoints.baseURL + path
        guard let url = URL(string: urlString) else { throw ApiError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await session.data(for: request)
        let apiResponse = try decoder.decode(ApiResponse<T>.self, from: data)

        guard apiResponse.success, let responseData = apiResponse.data else {
            throw ApiError.apiError(apiResponse.message ?? "操作失敗")
        }

        return responseData
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
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        _ = try await session.data(for: request)
    }

    func toggleAlert(id: Int, deviceToken: String) async throws {
        let encoded = deviceToken.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? deviceToken
        let urlString = "\(ApiEndpoints.baseURL)\(ApiEndpoints.alerts)/\(id)/toggle?deviceToken=\(encoded)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        _ = try await session.data(for: request)
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
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無效的 URL"
        case .serverError: return "伺服器錯誤"
        case .apiError(let msg): return msg
        }
    }
}
