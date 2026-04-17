import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject var settings: SettingsManager

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.6)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("行情")
                }

            AquaticView()
                .tabItem {
                    Image(systemName: "fish.fill")
                    Text("漁產")
                }

            LivestockView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("畜產")
                }

            OrganicView()
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("有機")
                }

            FlowerView()
                .tabItem {
                    Image(systemName: "camera.macro")
                    Text("花卉")
                }

            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("搜尋")
                }

            FavoritesView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("收藏")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("設定")
                }
        }
        .tint(AppColors.primary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(SettingsManager())
}
