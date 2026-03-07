import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("行情")
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
