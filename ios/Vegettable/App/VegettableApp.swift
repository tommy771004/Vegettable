import SwiftUI

@main
struct VegettableApp: App {
    @StateObject private var settings = SettingsManager()
    @StateObject private var networkMonitor = NetworkMonitor.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(settings)
                .environmentObject(networkMonitor)
        }
    }
}
