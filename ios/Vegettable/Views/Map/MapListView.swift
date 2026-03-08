import SwiftUI
import MapKit

struct MapListView: View {
    @State private var selectedRegion: String? = nil

    private let regions = ["全部", "北部", "中部", "南部", "東部"]

    var filteredMarkets: [MarketLocation] {
        guard let region = selectedRegion else {
            return MarketLocation.all
        }
        return MarketLocation.all.filter { $0.region == region }
    }

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            VStack(spacing: 0) {
                // 區域篩選
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(regions, id: \.self) { region in
                            LiquidChip(
                                label: region,
                                isSelected: (selectedRegion ?? "全部") == region || (selectedRegion == nil && region == "全部"),
                                action: {
                                    selectedRegion = region == "全部" ? nil : region
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 10)

                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredMarkets) { market in
                            GlassCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(market.name + "果菜批發市場")
                                            .font(.system(size: 17, weight: .semibold, design: .rounded))

                                        Text(market.address)
                                            .font(.system(size: 13, design: .rounded))
                                            .foregroundColor(AppColors.textSecondary)

                                        Text(market.region)
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 3)
                                            .foregroundColor(AppColors.primary)
                                            .background(
                                                Capsule()
                                                    .fill(AppColors.primary.opacity(0.1))
                                            )
                                    }

                                    Spacer()

                                    Button("導航") {
                                        openMaps(market: market)
                                    }
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 9)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [AppColors.primary, AppColors.primaryLight],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .shadow(color: AppColors.primary.opacity(0.3), radius: 6, y: 2)
                                }
                                .padding(18)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("批發市場位置")
    }

    private func openMaps(market: MarketLocation) {
        let coordinate = CLLocationCoordinate2D(latitude: market.latitude, longitude: market.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = market.name + "果菜批發市場"
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
