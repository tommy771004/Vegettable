import SwiftUI
import MapKit

struct WeatherView: View {
    @State private var observations: [WeatherObservation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedCounty: String = "全部"
    @State private var showMap = false

    private let counties = ["全部", "台北市", "新北市", "桃園市", "新竹縣", "苗栗縣",
                            "台中市", "彰化縣", "南投縣", "雲林縣", "嘉義縣",
                            "台南市", "高雄市", "屏東縣", "宜蘭縣", "花蓮縣", "台東縣"]

    private var filtered: [WeatherObservation] {
        observations.filter {
            let matchCounty = selectedCounty == "全部" || $0.county.contains(selectedCounty)
            let matchSearch = searchText.isEmpty ||
                $0.stationName.contains(searchText) ||
                $0.county.contains(searchText)
            return matchCounty && matchSearch
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#E3F2FD"), Color(hex: "#90CAF9")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 地圖/列表 切換
                    Picker("檢視方式", selection: $showMap) {
                        Label("列表", systemImage: "list.bullet").tag(false)
                        Label("地圖", systemImage: "map").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // 縣市篩選
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(counties, id: \.self) { county in
                                CategoryChip(
                                    label: county,
                                    isSelected: selectedCounty == county,
                                    action: { selectedCounty = county }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 6)

                    if isLoading && observations.isEmpty {
                        SkeletonListView(count: 8)
                    } else if let error = errorMessage, observations.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "cloud.slash")
                                .font(.system(size: 32))
                                .foregroundColor(AppColors.textTertiary)
                            Text(error)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                            Button("重試") { Task { await loadObservations() } }
                                .buttonStyle(.borderedProminent)
                                .tint(Color(hex: "#1565C0"))
                        }
                        .padding()
                        Spacer()
                    } else if showMap {
                        WeatherMapView(observations: filtered)
                    } else {
                        List {
                            ForEach(filtered) { obs in
                                WeatherRow(obs: obs)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                            }
                        }
                        .listStyle(.plain)
                        .refreshable { await loadObservations() }
                    }
                }
            }
            .navigationTitle("農業氣象")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "搜尋測站名稱或縣市")
            .task { await loadObservations() }
        }
    }

    private func loadObservations() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await ApiClient.shared.fetchWeatherObservations()
            await MainActor.run {
                observations = result
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - 氣象列表行
struct WeatherRow: View {
    let obs: WeatherObservation

    private var weatherIcon: String {
        switch obs.weatherSummary {
        case "Hot":   return "sun.max.fill"
        case "Warm":  return "sun.haze.fill"
        case "Cool":  return "cloud.sun.fill"
        case "Cold":  return "snowflake"
        case "Rainy": return "cloud.rain.fill"
        default:      return "cloud.fill"
        }
    }

    private var weatherColor: Color {
        switch obs.weatherSummary {
        case "Hot":   return .red
        case "Warm":  return .orange
        case "Cool":  return .blue
        case "Cold":  return .cyan
        case "Rainy": return Color(hex: "#1565C0")
        default:      return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 標題列
            HStack {
                Image(systemName: weatherIcon)
                    .foregroundColor(weatherColor)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(obs.stationName)
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text("\(obs.county) \(obs.township)")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                if let temp = obs.temperature {
                    Text(String(format: "%.1f°C", temp))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(weatherColor)
                }
            }

            // 觀測值網格
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                GridItem(.flexible()), GridItem(.flexible())],
                      spacing: 6) {
                WeatherDataCell(icon: "humidity.fill",
                    label: "濕度",
                    value: obs.relHumidity.map { String(format: "%.0f%%", $0) } ?? "—")
                WeatherDataCell(icon: "cloud.rain.fill",
                    label: "雨量",
                    value: obs.rainfall.map { String(format: "%.1fmm", $0) } ?? "—")
                WeatherDataCell(icon: "wind",
                    label: "風速",
                    value: obs.windSpeed.map { String(format: "%.1fm/s", $0) } ?? "—")
                WeatherDataCell(icon: "sun.max.fill",
                    label: "日照",
                    value: obs.sunshineHours.map { String(format: "%.1fhr", $0) } ?? "—")
            }

            Text(obs.obsTime)
                .font(.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

struct WeatherDataCell: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - 地圖視圖
struct WeatherMapView: View {
    let observations: [WeatherObservation]

    var body: some View {
        Map {
            ForEach(observations) { obs in
                if let lat = obs.latitude, let lon = obs.longitude {
                    Annotation(obs.stationName, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                        VStack(spacing: 2) {
                            ZStack {
                                Circle()
                                    .fill(tempColor(obs.temperature))
                                    .frame(width: 32, height: 32)
                                if let temp = obs.temperature {
                                    Text(String(format: "%.0f°", temp))
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            Text(obs.stationName)
                                .font(.system(size: 8))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, 4)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .mapStyle(.standard)
    }

    private func tempColor(_ temp: Double?) -> Color {
        guard let t = temp else { return .gray }
        if t > 30 { return .red }
        if t > 22 { return .orange }
        if t > 15 { return .blue }
        return .cyan
    }
}

#Preview {
    WeatherView()
}
