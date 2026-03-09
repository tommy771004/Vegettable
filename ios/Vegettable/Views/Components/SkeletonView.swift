import SwiftUI

// MARK: - 骨架屏元件
struct SkeletonRow: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                SkeletonBlock(width: 100, height: 18)
                SkeletonBlock(width: 60, height: 12)
                SkeletonBlock(width: 70, height: 20)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                SkeletonBlock(width: 80, height: 24)
                SkeletonBlock(width: 50, height: 12)
            }
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.3))
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 0.8)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct SkeletonBlock: View {
    let width: CGFloat
    let height: CGFloat
    @State private var shimmer = false

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.12),
                        Color.gray.opacity(0.06),
                        Color.gray.opacity(0.12),
                    ],
                    startPoint: shimmer ? .leading : .trailing,
                    endPoint: shimmer ? .trailing : .leading
                )
            )
            .frame(width: width, height: height)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    shimmer.toggle()
                }
            }
    }
}

struct SkeletonListView: View {
    let count: Int

    init(count: Int = 6) {
        self.count = count
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(0..<count, id: \.self) { _ in
                    SkeletonRow()
                }
            }
            .padding(.horizontal, 14)
        }
    }
}

// MARK: - 離線狀態橫幅
struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 12))
            Text("目前處於離線狀態，顯示快取資料")
                .font(.system(size: 12, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.9))
    }
}
