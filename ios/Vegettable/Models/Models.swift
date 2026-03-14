import Foundation

// MARK: - API 統一回應格式
struct ApiResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let timestamp: Int64
}

// MARK: - 產品摘要
struct ProductSummary: Codable, Identifiable {
    let cropCode: String
    let cropName: String
    let avgPrice: Double
    let prevAvgPrice: Double
    let historicalAvgPrice: Double
    let volume: Double
    let priceLevel: String
    let trend: String
    let recentPrices: [DailyPrice]
    let category: String
    let subCategory: String?
    let aliases: [String]

    var id: String { cropCode }
}

// MARK: - 每日價格
struct DailyPrice: Codable, Identifiable {
    let date: String
    let avgPrice: Double
    let volume: Double

    var id: String { date }
}

// MARK: - 月均價
struct MonthlyPrice: Codable, Identifiable {
    let month: String
    let avgPrice: Double
    let volume: Double

    var id: String { month }
}

// MARK: - 產品詳情
struct ProductDetail: Codable {
    let cropCode: String
    let cropName: String
    let aliases: [String]
    let category: String
    let subCategory: String?
    let avgPrice: Double
    let historicalAvgPrice: Double
    let priceLevel: String
    let trend: String
    let dailyPrices: [DailyPrice]
    let monthlyPrices: [MonthlyPrice]
}

// MARK: - 市場
struct Market: Codable, Identifiable {
    let marketCode: String
    let marketName: String
    let region: String

    var id: String { marketCode }
}

// MARK: - 市場價格
struct MarketPrice: Codable, Identifiable {
    let marketName: String
    let cropName: String
    let avgPrice: Double
    let upperPrice: Double
    let lowerPrice: Double
    let volume: Double
    let transDate: String

    var id: String { marketName + transDate }
}

// MARK: - 價格警示
struct PriceAlert: Codable, Identifiable {
    let id: Int
    let cropName: String
    let targetPrice: Double
    let condition: String // "below" | "above"
    let isActive: Bool
    let lastTriggeredAt: String?
    let createdAt: String
}

struct CreateAlertRequest: Codable {
    let deviceToken: String
    let cropName: String
    let targetPrice: Double
    let condition: String
}

// MARK: - AI 價格預測
struct PricePrediction: Codable {
    let cropName: String
    let currentPrice: Double
    let predictedPrice: Double
    let changePercent: Double
    let direction: String // "up" | "down" | "stable"
    let confidence: Double
    let reasoning: String
}

// MARK: - 季節性資訊
struct SeasonalInfo: Codable, Identifiable {
    let cropName: String
    let category: String
    let peakMonths: [Int]
    let isInSeason: Bool
    let seasonNote: String

    var id: String { cropName }
}

// MARK: - 食譜
struct Recipe: Codable, Identifiable {
    let name: String
    let description: String
    let ingredients: [String]
    let difficulty: String // "easy" | "medium" | "hard"
    let cookTimeMinutes: Int

    var id: String { name }
}

// MARK: - 分類
enum CropCategory: String, CaseIterable {
    case all = "all"
    case vegetable = "vegetable"
    case fruit = "fruit"
    case fish = "fish"
    case meat = "meat"
    case flower = "flower"
    case rice = "rice"

    var label: String {
        switch self {
        case .all: return "全部"
        case .vegetable: return "蔬菜"
        case .fruit: return "水果"
        case .fish: return "漁產"
        case .meat: return "肉品"
        case .flower: return "花卉"
        case .rice: return "白米"
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .vegetable: return "leaf"
        case .fruit: return "apple.logo"
        case .fish: return "fish"
        case .meat: return "fork.knife"
        case .flower: return "camera.macro"
        case .rice: return "circle.grid.3x3"
        }
    }

    var color: String {
        switch self {
        case .all: return "#2E7D32"
        case .vegetable: return "#4CAF50"
        case .fruit: return "#FF9800"
        case .fish: return "#2196F3"
        case .meat: return "#F44336"
        case .flower: return "#E91E63"
        case .rice: return "#795548"
        }
    }

    var apiValue: String? {
        self == .all ? nil : rawValue
    }
}

// MARK: - 市場位置
struct MarketLocation: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let region: String
    let latitude: Double
    let longitude: Double

    static let all: [MarketLocation] = [
        MarketLocation(name: "台北一", address: "台北市萬華區萬大路533號", region: "北部", latitude: 25.0258, longitude: 121.5010),
        MarketLocation(name: "台北二", address: "台北市中山區民族東路336號", region: "北部", latitude: 25.0690, longitude: 121.5375),
        MarketLocation(name: "三重", address: "新北市三重區大同北路107號", region: "北部", latitude: 25.0620, longitude: 121.4872),
        MarketLocation(name: "桃園", address: "桃園市桃園區中山路590號", region: "北部", latitude: 24.9917, longitude: 121.3125),
        MarketLocation(name: "台中", address: "台中市西屯區中清路350號", region: "中部", latitude: 24.1795, longitude: 120.6547),
        MarketLocation(name: "溪湖", address: "彰化縣溪湖鎮彰水路四段510號", region: "中部", latitude: 23.9617, longitude: 120.4793),
        MarketLocation(name: "西螺", address: "雲林縣西螺鎮九隆里延平路248號", region: "中部", latitude: 23.7983, longitude: 120.4602),
        MarketLocation(name: "嘉義", address: "嘉義市西區博愛路二段459號", region: "南部", latitude: 23.4817, longitude: 120.4343),
        MarketLocation(name: "台南", address: "台南市北區忠北街7號", region: "南部", latitude: 23.0125, longitude: 120.2153),
        MarketLocation(name: "鳳山", address: "高雄市鳳山區建國路三段39號", region: "南部", latitude: 22.6273, longitude: 120.3419),
        MarketLocation(name: "屏東", address: "屏東縣屏東市工業路9號", region: "南部", latitude: 22.6656, longitude: 120.4950),
        MarketLocation(name: "宜蘭", address: "宜蘭縣宜蘭市環市東路二段1號", region: "東部", latitude: 24.7469, longitude: 121.7515),
        MarketLocation(name: "花蓮", address: "花蓮縣花蓮市中華路100號", region: "東部", latitude: 23.9872, longitude: 121.6044),
    ]
}
