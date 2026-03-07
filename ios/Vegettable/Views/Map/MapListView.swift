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
            LinearGradient(colors: [AppColors.background, AppColors.backgroundEnd],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 區域篩選
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(regions, id: \.self) { region in
                            CategoryChip(
                                label: region,
                                isSelected: (selectedRegion ?? "全部") == region || (selectedRegion == nil && region == "全部"),
                                action: {
                                    selectedRegion = region == "全部" ? nil : region
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                List {
                    ForEach(filteredMarkets) { market in
                        GlassCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(market.name + "果菜批發市場")
                                        .font(.headline)

                                    Text(market.address)
                                        .font(.caption)
                                        .foregroundColor(AppColors.textSecondary)

                                    Text(market.region)
                                        .font(.caption2)
                                        .foregroundColor(AppColors.textTertiary)
                                }

                                Spacer()

                                Button("導航") {
                                    openMaps(market: market)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(AppColors.primary)
                                .controlSize(.small)
                            }
                            .padding(16)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    }
                }
                .listStyle(.plain)
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
