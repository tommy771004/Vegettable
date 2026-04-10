import SwiftUI

struct FeedbackView: View {
    @Binding var isPresented: Bool
    @State private var feedbackText = ""
    @State private var feedbackType: FeedbackType = .suggestion
    @State private var showSuccessMessage = false
    @State private var showErrorMessage = false
    @State private var errorText = ""
    @State private var isSubmitting = false
    @Environment(\.dismiss) var dismiss
    private let logger = DebugLogger.shared

    enum FeedbackType: String, CaseIterable {
        case bug = "錯誤報告"
        case suggestion = "功能建議"
        case other = "其他"

        var apiValue: String {
            switch self {
            case .bug: return "bug"
            case .suggestion: return "suggestion"
            case .other: return "other"
            }
        }
    }

    var isFormValid: Bool {
        let trimmed = feedbackText.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed.count >= 10 && trimmed.count <= 2000
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [AppColors.background, AppColors.backgroundEnd],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("反饋類型", systemImage: "tag")
                                .font(.headline)
                                .foregroundColor(AppColors.primary)
                                .accessibilityAddTraits(.isHeader)

                            Picker("反饋類型", selection: $feedbackType) {
                                ForEach(FeedbackType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            .accessibilityLabel("選擇反饋類型")
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 12) {
                            Label("詳細描述", systemImage: "pencil")
                                .font(.headline)
                                .foregroundColor(AppColors.primary)
                                .accessibilityAddTraits(.isHeader)

                            TextEditor(text: $feedbackText)
                                .frame(height: 150)
                                .scrollContentBackground(.hidden)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1))
                                .accessibilityLabel("反饋詳細描述")
                                .accessibilityHint("請輸入10-2000個字的反饋內容")

                            HStack {
                                Text("\(feedbackText.count)/2000")
                                    .font(.caption2)
                                    .foregroundColor(feedbackText.count > 2000 ? AppColors.error : AppColors.textTertiary)
                                Spacer()
                                if feedbackText.count < 10 {
                                    Text("最少需要 \(10 - feedbackText.count) 個字")
                                        .font(.caption2)
                                        .foregroundColor(AppColors.warning)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)

                        Spacer()
                        
                        if showErrorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(errorText)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }

                        HStack(spacing: 12) {
                            Button(action: { dismiss() }) {
                                Text("取消")
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(8)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            .accessibilityLabel("取消提交反饋")

                            Button(action: submitFeedback) {
                                if isSubmitting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("提交")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(isFormValid && !isSubmitting ? AppColors.primary : Color.gray.opacity(0.3))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .disabled(!isFormValid || isSubmitting)
                            .accessibilityLabel("提交反饋")
                            .accessibilityHint(isFormValid ? "點擊提交您的反饋" : "請完整填寫表單才能提交")
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("提交反饋")
            .navigationBarTitleDisplayMode(.inline)
            .alert("感謝您的反饋", isPresented: $showSuccessMessage) {
                Button("確認") {
                    logger.info("反饋提交成功")
                    dismiss()
                }
            } message: {
                Text("我們已收到您的反饋，謝謝您幫助我們改進應用程式。")
            }
        }
    }

    private func submitFeedback() {
        let trimmedText = feedbackText.trimmingCharacters(in: .whitespaces)

        guard trimmedText.count >= 10 else {
            errorText = "反饋內容至少需要10個字"
            showErrorMessage = true
            logger.warning("反饋提交失敗: 內容過短")
            return
        }

        guard trimmedText.count <= 2000 else {
            errorText = "反饋內容不能超過2000個字"
            showErrorMessage = true
            logger.warning("反饋提交失敗: 內容過長")
            return
        }

        isSubmitting = true
        showErrorMessage = false
        logger.debug("提交反饋: 類型=\(feedbackType.rawValue), 長度=\(trimmedText.count)")

        Task {
            do {
                _ = try await ApiClient.shared.submitFeedback(
                    type: feedbackType.apiValue,
                    content: trimmedText
                )
                await MainActor.run {
                    isSubmitting = false
                    showSuccessMessage = true
                    logger.info("反饋提交成功")
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorText = "提交失敗，請檢查網路連接後重試"
                    showErrorMessage = true
                    logger.error("反饋提交失敗: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    @State var isPresented = true
    return FeedbackView(isPresented: $isPresented)
}
