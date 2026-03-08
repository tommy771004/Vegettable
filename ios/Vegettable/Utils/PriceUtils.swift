import SwiftUI

// MARK: - 價格工具
struct PriceUtils {
    static let kgToCatty = 0.6
    static let retailMultiplier = 2.5

    static func convertToCatty(_ kgPrice: Double) -> Double {
        return kgPrice * kgToCatty
    }

    static func estimateRetail(_ wholesalePrice: Double) -> Double {
        return wholesalePrice * retailMultiplier
    }

    static func formatPrice(_ price: Double) -> String {
        if price == Double(Int(price)) {
            return String(Int(price))
        }
        return String(format: "%.1f", price)
    }

    static func priceLevelColor(_ level: String) -> Color {
        switch level {
        case "very-cheap": return Color(hex: "#E53935")
        case "cheap":      return Color(hex: "#FF7043")
        case "normal":     return Color(hex: "#42A5F5")
        case "expensive":  return Color(hex: "#1565C0")
        default:           return .gray
        }
    }

    static func priceLevelBgColor(_ level: String) -> Color {
        priceLevelColor(level).opacity(0.12)
    }

    static func priceLevelLabel(_ level: String) -> String {
        switch level {
        case "very-cheap": return "當令便宜"
        case "cheap":      return "相對便宜"
        case "normal":     return "略偏貴"
        case "expensive":  return "相對偏貴"
        default:           return ""
        }
    }

    static func trendArrow(_ trend: String) -> String {
        switch trend {
        case "up":   return "↑"
        case "down": return "↓"
        default:     return "→"
        }
    }

    static func trendColor(_ trend: String) -> Color {
        switch trend {
        case "up":   return Color(hex: "#E53935")
        case "down": return Color(hex: "#2E7D32")
        default:     return .gray
        }
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Liquid Glass 主題色 (iOS 26 / visionOS 風格)
struct AppColors {
    // 主色調 — 使用通透感更強的色彩
    static let primary = Color(hex: "#1B8A50")
    static let primaryLight = Color(hex: "#43A047")
    static let primaryDark = Color(hex: "#0D5C2F")

    // Liquid Glass 背景 — 柔和漸層
    static let background = Color(hex: "#F0F4F8")
    static let backgroundEnd = Color(hex: "#E1E8EF")

    // 表面與玻璃材質
    static let surface = Color.white.opacity(0.85)
    static let glassBg = Color.white.opacity(0.45)
    static let glassStroke = Color.white.opacity(0.6)

    // 文字
    static let textPrimary = Color(hex: "#0F1419")
    static let textSecondary = Color(hex: "#536471")
    static let textTertiary = Color(hex: "#8899A6")
}
