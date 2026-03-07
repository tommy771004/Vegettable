import SwiftUI

@main
struct VegettableApp: App {
    @StateObject private var settings = SettingsManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(settings)
        }
    }
}
