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
        case "very-cheap": return Color(hex: "#D32F2F")
        case "cheap":      return Color(hex: "#FF8A80")
        case "normal":     return Color(hex: "#82B1FF")
        case "expensive":  return Color(hex: "#1565C0")
        default:           return .gray
        }
    }

    static func priceLevelBgColor(_ level: String) -> Color {
        priceLevelColor(level).opacity(0.1)
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

    /// 價格等級輔助圖示（輔助顏色以外的視覺提示，符合 WCAG 2.1）
    static func priceLevelIcon(_ level: String) -> String {
        switch level {
        case "very-cheap": return "↓↓"
        case "cheap":      return "↓"
        case "normal":     return "→"
        case "expensive":  return "↑"
        default:           return ""
        }
    }

    /// 趨勢的無障礙描述（螢幕閱讀器用）
    static func trendAccessibilityLabel(_ trend: String) -> String {
        switch trend {
        case "up":   return "上漲"
        case "down": return "下跌"
        default:     return "持平"
        }
    }

    /// 價格等級的完整無障礙描述
    static func priceLevelAccessibilityLabel(_ level: String) -> String {
        switch level {
        case "very-cheap": return "價格當令便宜"
        case "cheap":      return "價格相對便宜"
        case "normal":     return "價格略偏貴"
        case "expensive":  return "價格相對偏貴"
        default:           return "價格未知"
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
        case "up":   return Color(hex: "#D32F2F")
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

// MARK: - 主題色
struct AppColors {
    static let primary = Color(hex: "#2E7D32")
    static let primaryLight = Color(hex: "#4CAF50")
    static let primaryDark = Color(hex: "#1B5E20")
    static let background = Color(hex: "#E8F5E9")
    static let backgroundEnd = Color(hex: "#C8E6C9")
    static let surface = Color.white
    static let textPrimary = Color(hex: "#1B1B1F")
    static let textSecondary = Color(hex: "#49454F")
    static let textTertiary = Color(hex: "#79747E")
    static let glassBg = Color.white.opacity(0.72)
}
