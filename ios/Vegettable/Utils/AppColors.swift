import SwiftUI
import UIKit

/// 動態色票：依系統明暗模式切換，實現沈浸式 UI。
/// 使用 UIColor 的 dynamicProvider 以在 Light / Dark 下自動取得對應色值。
struct AppColors {
    // 主色 — 蔬果行情的自然綠，於深色模式略為提亮以保證對比。
    static let primary = dynamic(light: rgb(0.11, 0.54, 0.31),
                                 dark:  rgb(0.34, 0.78, 0.48))
    static let primaryLight = dynamic(light: rgb(0.60, 0.90, 0.40),
                                      dark:  rgb(0.45, 0.82, 0.55))

    // 背景漸層
    static let background = dynamic(light: rgb(0.98, 0.98, 0.99),
                                    dark:  rgb(0.06, 0.08, 0.10))
    static let backgroundEnd = dynamic(light: rgb(0.95, 0.97, 0.96),
                                       dark:  rgb(0.10, 0.13, 0.12))

    // 文字
    static let textPrimary = dynamic(light: rgb(0.06, 0.08, 0.10),
                                     dark:  rgb(0.96, 0.97, 0.98))
    static let textSecondary = dynamic(light: rgb(0.33, 0.39, 0.44),
                                       dark:  rgb(0.72, 0.76, 0.80))
    static let textTertiary = dynamic(light: rgb(0.54, 0.60, 0.65),
                                      dark:  rgb(0.56, 0.60, 0.64))

    // 語意色
    static let success = dynamic(light: rgb(0.18, 0.69, 0.32),
                                 dark:  rgb(0.35, 0.82, 0.48))
    static let warning = dynamic(light: rgb(0.96, 0.60, 0.00),
                                 dark:  rgb(1.00, 0.74, 0.26))
    static let error = dynamic(light: rgb(0.90, 0.22, 0.21),
                               dark:  rgb(1.00, 0.42, 0.40))

    // Liquid Glass：半透明底色，在深色模式使用深色半透明以提升對比。
    static let glassBg = dynamic(light: UIColor.white.withAlphaComponent(0.55),
                                 dark:  UIColor(white: 1.0, alpha: 0.08))
    static let glassStroke = dynamic(light: UIColor.black.withAlphaComponent(0.08),
                                     dark:  UIColor.white.withAlphaComponent(0.12))

    // MARK: - Helpers
    private static func rgb(_ r: Double, _ g: Double, _ b: Double) -> UIColor {
        UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }
}

extension Color {
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: trimmed)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xff0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00ff00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000ff) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
