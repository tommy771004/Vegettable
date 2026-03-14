import SwiftUI

struct OrganicView: View {
    @State private var prices: [OrganicPrice] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedCertType: String = "全部"

    private let certTypes = ["全部", "有機", "產銷履歷"]

    private var filtered: [OrganicPrice] {
        prices.filter { item in
            let matchesCert = selectedCertType == "全部" || item.certType == selectedCertType
            let matchesSearch = searchText.isEmpty || item.cropName.contains(searchText)
            return matchesCert && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#E8F5E9"), Color(hex: "#C8E6C9")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 認證類型篩選
                    HStack(spacing: 8) {
                        ForEach(certTypes, id: \.self) { cert in
                            CategoryChip(
                                label: cert,
                                isSelected: selectedCertType == cert,
                                action: { selectedCertType = cert }
                            )
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    if isLoading && prices.isEmpty {
                        SkeletonListView(count: 8)
                    } else if let error = errorMessage, prices.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(AppColors.textTertiary)
                            Text(error)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                            Button("重試") { Task { await loadPrices() } }
                                .buttonStyle(.borderedProminent)
                                .tint(AppColors.primary)
                        }
                        .padding()
                        Spacer()
                    } else if filtered.isEmpty {
                        Spacer()
                        Text(searchText.isEmpty ? "目前無有機行情資料" : "找不到相關產品")
                            .foregroundColor(AppColors.textTertiary)
                        Spacer()
                    } else {
                        List {
                            ForEach(filtered) { item in
                                OrganicRow(item: item)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                            }
                        }
                        .listStyle(.plain)
                        .refreshable { await loadPrices() }
                    }
                }
            }
            .navigationTitle("有機行情")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "搜尋作物名稱")
            .task { await loadPrices() }
        }
    }

    private func loadPrices() async {
        isLoading = true
        errorMessage = nil
        let certParam = selectedCertType == "全部" ? nil : selectedCertType
        do {
            let result = try await ApiClient.shared.fetchOrganicPrices(certType: certParam)
            await MainActor.run {
                prices = result
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

struct OrganicRow: View {
    let item: OrganicPrice

    var certColor: Color {
        item.certType == "有機" ? Color(hex: "#2E7D32") : Color(hex: "#1565C0")
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.cropName)
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text(item.certType)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(certColor.opacity(0.12))
                        .foregroundColor(certColor)
                        .clipShape(Capsule())
                }
                Text(item.marketName)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                Text(item.transDate)
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f", NSDecimalNumber(decimal: item.avgPrice).doubleValue))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primary)
                Text("元/公斤")
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)
                if let premium = item.premiumPercent {
                    let val = NSDecimalNumber(decimal: premium).doubleValue
                    Text(String(format: "%+.1f%%", val))
                        .font(.caption2)
                        .foregroundColor(val >= 0 ? .red : .green)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

#Preview {
    OrganicView()
}
