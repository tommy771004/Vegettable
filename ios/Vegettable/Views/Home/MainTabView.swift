import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // 內容
            Group {
                switch selectedTab {
                case 0: HomeView()
                case 1: SearchView()
                case 2: FavoritesView()
                case 3: SettingsView()
                default: HomeView()
                }
            }

            // Liquid Glass 浮動 Tab Bar
            HStack(spacing: 0) {
                TabBarItem(icon: "chart.line.uptrend.xyaxis", label: "行情", isSelected: selectedTab == 0)
                    .onTapGesture { withAnimation(.spring(response: 0.35)) { selectedTab = 0 } }

                TabBarItem(icon: "magnifyingglass", label: "搜尋", isSelected: selectedTab == 1)
                    .onTapGesture { withAnimation(.spring(response: 0.35)) { selectedTab = 1 } }

                TabBarItem(icon: "heart.fill", label: "收藏", isSelected: selectedTab == 2)
                    .onTapGesture { withAnimation(.spring(response: 0.35)) { selectedTab = 2 } }

                TabBarItem(icon: "gearshape", label: "設定", isSelected: selectedTab == 3)
                    .onTapGesture { withAnimation(.spring(response: 0.35)) { selectedTab = 3 } }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    Capsule()
                        .fill(.ultraThinMaterial)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.5), Color.white.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.7), Color.white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: .black.opacity(0.1), radius: 20, y: 6)
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
            .padding(.horizontal, 40)
            .padding(.bottom, 12)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: isSelected ? 19 : 17, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? AppColors.primary : AppColors.textTertiary)

            Text(label)
                .font(.system(size: 10, weight: isSelected ? .semibold : .regular, design: .rounded))
                .foregroundColor(isSelected ? AppColors.primary : AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            Group {
                if isSelected {
                    Capsule().fill(AppColors.primary.opacity(0.1))
                        .padding(.horizontal, 4)
                }
            }
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAddTraits(.isButton)
    }
}
