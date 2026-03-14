import SwiftUI

struct AppColors {
    static let primary = Color(red: 0.2, green: 0.7, blue: 0.3) // 綠色主色
    static let primaryLight = Color(red: 0.6, green: 0.9, blue: 0.4) // 淺綠
    static let background = Color(red: 0.98, green: 0.98, blue: 0.99) // 淺色背景
    static let backgroundEnd = Color(red: 0.95, green: 0.97, blue: 0.96) // 漸變終點
    static let textPrimary = Color(red: 0.1, green: 0.1, blue: 0.1) // 主文字
    static let textSecondary = Color(red: 0.5, green: 0.5, blue: 0.5) // 次文字
    static let textTertiary = Color(red: 0.7, green: 0.7, blue: 0.7) // 三級文字
    static let success = Color(red: 0.2, green: 0.8, blue: 0.3)
    static let warning = Color(red: 1.0, green: 0.7, blue: 0.0)
    static let error = Color(red: 1.0, green: 0.2, blue: 0.2)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let red = Double((rgbValue & 0xff0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00ff00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000ff) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}
