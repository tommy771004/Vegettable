import SwiftUI
import MapKit

struct MapListView: View {
    @State private var selectedRegion: String? = nil
    @State private var errorMessage: String? = nil
    private let logger = DebugLogger.shared
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
                                    logger.debug("選擇區域: \(region)")
                                    selectedRegion = region == "全部" ? nil : region
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                // 錯誤信息顯示
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                        Button(action: { errorMessage = nil }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                if filteredMarkets.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "map")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.textTertiary)
                        Text("未找到市場")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredMarkets) { market in
                            GlassCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(market.name + "果菜批發市場")
                                            .font(.headline)
                                            .accessibilityLabel("市場: \(market.name)果菜批發市場")

                                        Text(market.address)
                                            .font(.caption)
                                            .foregroundColor(AppColors.textSecondary)

                                        Text(market.region)
                                            .font(.caption2)
                                            .foregroundColor(AppColors.textTertiary)
                                    }

                                    Spacer()

                                    Button(action: { openMaps(market: market) }) {
                                        Text("導航")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(AppColors.primary)
                                    .controlSize(.small)
                                    .accessibilityLabel("導航至\(market.name)果菜批發市場")
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
        }
        .navigationTitle("批發市場位置")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openMaps(market: MarketLocation) {
        do {
            let coordinate = CLLocationCoordinate2D(latitude: market.latitude, longitude: market.longitude)
            
            // 驗證座標有效性
            guard CLLocationCoordinate2DIsValid(coordinate) else {
                logger.error("無效的座標: \(market.latitude), \(market.longitude)")
                errorMessage = "市場座標無效，無法導航"
                return
            }
            
            let placemark = MKPlacemark(coordinate: coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = market.name + "果菜批發市場"
            
            logger.info("打開地圖導航: \(mapItem.name)")
            
            mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
        } catch {
            logger.error("導航失敗: \(error.localizedDescription)")
            errorMessage = "導航功能不可用，請稍後重試"
        }
    }
}

#Preview {
    NavigationStack {
        MapListView()
    }
}
