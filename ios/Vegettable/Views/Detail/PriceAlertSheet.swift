import SwiftUI
import UserNotifications

/// 設定 / 管理價格警示的 Sheet
struct PriceAlertSheet: View {
    let cropName: String
    let currentPrice: Double

    @Binding var isPresented: Bool
    @EnvironmentObject var settings: SettingsManager

    @State private var targetPriceText: String = ""
    @State private var condition: String = "below"
    @State private var isSubmitting = false
    @State private var alerts: [PriceAlert] = []
    @State private var isLoadingAlerts = true
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private let logger = LoggerManager.shared

    private var deviceToken: String {
        if let token = UserDefaults.standard.string(forKey: "deviceToken") {
            return token
        }
        let newToken = "ios-\(UUID().uuidString)"
        UserDefaults.standard.set(newToken, forKey: "deviceToken")
        return newToken
    }

    private var targetPrice: Double? {
        Double(targetPriceText.trimmingCharacters(in: .whitespaces))
    }

    private var priceValidationError: String? {
        guard let price = targetPrice else { return "請輸入數字" }
        if price <= 0 { return "價格必須大於 0" }
        if price > 99999 { return "價格不得超過 99,999 元" }
        return nil
    }

    private var isFormValid: Bool { priceValidationError == nil && !targetPriceText.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [AppColors.background, AppColors.backgroundEnd],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // 目前價格提示
                        GlassCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(cropName)
                                        .font(.headline)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("目前均價：\(PriceUtils.formatPrice(settings.displayPrice(currentPrice))) \(settings.unitLabel)")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "bell.badge")
                                    .font(.title2)
                                    .foregroundColor(AppColors.primary)
                            }
                            .padding(16)
                        }

                        // 新增警示表單
                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("新增價格警示", systemImage: "plus.circle")
                                    .font(.headline)
                                    .foregroundColor(AppColors.primary)

                                // 條件選擇
                                HStack {
                                    Text("通知條件")
                                        .foregroundColor(AppColors.textSecondary)
                                    Spacer()
                                    Picker("條件", selection: $condition) {
                                        Text("低於目標").tag("below")
                                        Text("高於目標").tag("above")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 180)
                                }

                                // 目標價格輸入
                                HStack {
                                    Text("目標價格")
                                        .foregroundColor(AppColors.textSecondary)
                                    Spacer()
                                    TextField("例: 30.0", text: $targetPriceText)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 100)
                                        .padding(8)
                                        .background(Color.white.opacity(0.15))
                                        .cornerRadius(8)
                                    Text("元/公斤")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textTertiary)
                                }

                                // 即時驗證提示
                                if !targetPriceText.isEmpty, let validErr = priceValidationError {
                                    Label(validErr, systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }

                                // API 錯誤 / 成功訊息
                                if let err = errorMessage {
                                    Label(err, systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                if let ok = successMessage {
                                    Label(ok, systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(AppColors.success)
                                }

                                Button(action: createAlert) {
                                    if isSubmitting {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("建立警示")
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding(12)
                                .background(isFormValid && !isSubmitting ? AppColors.primary : Color.gray.opacity(0.4))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .disabled(!isFormValid || isSubmitting)
                            }
                            .padding(16)
                        }

                        // 現有警示清單
                        if isLoadingAlerts {
                            ProgressView("載入警示中…")
                                .padding()
                        } else if !alerts.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 0) {
                                    Label("現有警示", systemImage: "list.bullet.rectangle")
                                        .font(.headline)
                                        .foregroundColor(AppColors.primary)
                                        .padding(.bottom, 8)

                                    ForEach(alerts) { alert in
                                        alertRow(alert)
                                        if alert.id != alerts.last?.id {
                                            Divider().padding(.vertical, 4)
                                        }
                                    }
                                }
                                .padding(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("價格警示")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") { isPresented = false }
                }
            }
            .onAppear { loadAlerts() }
        }
    }

    // MARK: - Alert Row
    private func alertRow(_ alert: PriceAlert) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                let condText = alert.condition == "below" ? "低於" : "高於"
                Text("\(condText) \(PriceUtils.formatPrice(alert.targetPrice)) 元/公斤")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                if let triggered = alert.lastTriggeredAt {
                    Text("上次觸發：\(triggered)")
                        .font(.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            Spacer()

            // 啟用切換
            Button(action: { toggleAlert(alert) }) {
                Image(systemName: alert.isActive ? "bell.fill" : "bell.slash")
                    .foregroundColor(alert.isActive ? AppColors.primary : AppColors.textTertiary)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)

            // 刪除
            Button(action: { deleteAlert(alert) }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    // MARK: - API Calls
    private func loadAlerts() {
        isLoadingAlerts = true
        Task {
            do {
                let result = try await ApiClient.shared.fetchAlerts(deviceToken: deviceToken)
                await MainActor.run {
                    alerts = result.filter { $0.cropName == cropName }
                    isLoadingAlerts = false
                }
            } catch {
                await MainActor.run {
                    isLoadingAlerts = false
                    logger.log("載入警示失敗: \(error.localizedDescription)", level: .warning)
                }
            }
        }
    }

    private func createAlert() {
        guard let price = targetPrice, price > 0 else { return }
        isSubmitting = true
        errorMessage = nil
        successMessage = nil

        Task {
            // 確保推播權限已授予，未授予則先請求
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus != .authorized {
                let granted = await AppDelegate.requestNotificationPermission()
                if !granted {
                    await MainActor.run {
                        errorMessage = "需要允許推播通知才能接收價格警示"
                        isSubmitting = false
                    }
                    return
                }
                // 等待 APNs token 寫入 UserDefaults（最多 2 秒）
                var waited = 0
                while UserDefaults.standard.string(forKey: "deviceToken")?.hasPrefix("ios-") == false && waited < 20 {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    waited += 1
                }
            }

            let request = CreateAlertRequest(
                deviceToken: deviceToken,
                cropName: cropName,
                targetPrice: price,
                condition: condition
            )

            do {
                let newAlert = try await ApiClient.shared.createAlert(request: request)
                await MainActor.run {
                    alerts.insert(newAlert, at: 0)
                    targetPriceText = ""
                    successMessage = "警示已建立！價格\(condition == "below" ? "低於" : "高於") \(PriceUtils.formatPrice(price)) 元時將通知您"
                    isSubmitting = false
                    logger.log("建立警示成功: \(cropName) \(condition) \(price)", level: .info)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "建立失敗：\(error.localizedDescription)"
                    isSubmitting = false
                    logger.log("建立警示失敗: \(error.localizedDescription)", level: .error)
                }
            }
        }
    }

    private func toggleAlert(_ alert: PriceAlert) {
        Task {
            do {
                try await ApiClient.shared.toggleAlert(id: alert.id, deviceToken: deviceToken)
                await MainActor.run { loadAlerts() }
            } catch {
                logger.log("切換警示失敗: \(error.localizedDescription)", level: .warning)
            }
        }
    }

    private func deleteAlert(_ alert: PriceAlert) {
        Task {
            do {
                try await ApiClient.shared.deleteAlert(id: alert.id, deviceToken: deviceToken)
                await MainActor.run {
                    alerts.removeAll { $0.id == alert.id }
                    logger.log("刪除警示成功: id=\(alert.id)", level: .info)
                }
            } catch {
                logger.log("刪除警示失敗: \(error.localizedDescription)", level: .warning)
            }
        }
    }
}
