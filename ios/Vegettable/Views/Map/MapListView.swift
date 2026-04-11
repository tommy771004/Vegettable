import SwiftUI
import MapKit

struct MapListView: View {
    @State private var markets: [MarketLocation] = []
    @State private var isLoading = true
    @State private var selectedRegion: String? = nil
    @State private var errorMessage: String? = nil
    @State private var showMapView: Bool = false
    @State private var selectedMarket: MarketLocation? = nil
    private let logger = DebugLogger.shared
    private let regions = ["全部", "北部", "中部", "南部", "東部"]

    var filteredMarkets: [MarketLocation] {
        guard let region = selectedRegion else { return markets }
        return markets.filter { $0.region == region }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppColors.background, AppColors.backgroundEnd],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 區域篩選 + 地圖/清單切換
                HStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(regions, id: \.self) { region in
                                CategoryChip(
                                    label: region,
                                    isSelected: (selectedRegion ?? "全部") == region,
                                    action: {
                                        selectedRegion = region == "全部" ? nil : region
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // 地圖 / 清單切換按鈕
                    Button(action: { withAnimation { showMapView.toggle() } }) {
                        Image(systemName: showMapView ? "list.bullet" : "map")
                            .foregroundColor(AppColors.primary)
                            .padding(8)
                    }
                    .accessibilityLabel(showMapView ? "切換為清單視圖" : "切換為地圖視圖")
                    .padding(.trailing, 8)
                }
                .padding(.vertical, 8)

                // 錯誤訊息
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        Text(error).font(.caption).foregroundColor(.orange)
                        Spacer()
                        Button(action: { errorMessage = nil }) {
                            Image(systemName: "xmark").foregroundColor(.orange)
                        }
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 4)
                }

                if isLoading {
                    ProgressView("載入市場資料…").padding()
                } else if showMapView {
                    // ── 地圖視圖 ──────────────────────────────────────
                    MarketMapView(markets: filteredMarkets, onNavigate: openMaps)
                } else {
                    // ── 清單視圖 ──────────────────────────────────────
                    if filteredMarkets.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "map").font(.system(size: 40))
                                .foregroundColor(AppColors.textTertiary)
                            Text("未找到市場").foregroundColor(AppColors.textSecondary)
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
                                            Text(market.address).font(.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                            Text(market.region).font(.caption2)
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
        }
        .navigationTitle("批發市場位置")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadMarkets() }
    }

    private func loadMarkets() async {
        isLoading = true
        do {
            let result = try await ApiClient.shared.fetchMarkets()
            await MainActor.run {
                markets = result.map { $0.asLocation }
                isLoading = false
                logger.info("載入 \(markets.count) 個市場")
            }
        } catch {
            await MainActor.run {
                markets = MarketLocation.all
                isLoading = false
                errorMessage = "市場資料載入失敗，目前顯示預設資料（座標可能不是最新）"
                logger.warning("市場 API 載入失敗，使用靜態資料: \(error.localizedDescription)")
            }
        }
    }

    private func openMaps(market: MarketLocation) {
        let coordinate = CLLocationCoordinate2D(latitude: market.latitude, longitude: market.longitude)
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            errorMessage = "市場座標無效，無法導航"
            return
        }
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = market.name + "果菜批發市場"
        logger.info("打開地圖導航: \(mapItem.name ?? "")")
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

// MARK: - 地圖子視圖
struct MarketMapView: View {
    let markets: [MarketLocation]
    let onNavigate: (MarketLocation) -> Void

    @State private var selectedMarket: MarketLocation? = nil
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.8, longitude: 121.0),
        span: MKCoordinateSpan(latitudeDelta: 4.5, longitudeDelta: 3.0)
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region, annotationItems: markets) { market in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: market.latitude,
                    longitude: market.longitude
                )) {
                    Button(action: {
                        withAnimation { selectedMarket = market }
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "storefront.fill")
                                .foregroundColor(selectedMarket?.id == market.id ? AppColors.primary : .gray)
                                .font(.title3)
                            Text(market.name)
                                .font(.caption2)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.85))
                                .cornerRadius(4)
                        }
                    }
                    .accessibilityLabel("市場: \(market.name)")
                }
            }
            .ignoresSafeArea(edges: .bottom)

            // 選中市場的資訊卡
            if let market = selectedMarket {
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(market.name + "果菜批發市場")
                                .font(.headline)
                            Text(market.address).font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                        Button(action: { onNavigate(market) }) {
                            Label("導航", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.primary)
                        .controlSize(.regular)
                    }
                    .padding(16)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: markets) { newMarkets in
            if let first = newMarkets.first {
                withAnimation {
                    region.center = CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude)
                }
            }
            selectedMarket = nil
        }
    }
}

#Preview {
    NavigationStack {
        MapListView()
    }
}
