import SwiftUI
import DesignSystem

/// Snapchat-style story viewer for scan photos.
/// Shows front → side → back with a segmented progress bar at the top.
/// Tap right side to advance, left side to go back, swipe down to dismiss.
struct ScanStoryView: View {
    let snapshot: ScanSnapshot
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var barProgress: CGFloat = 0
    @State private var tickTimer: Timer?
    @GestureState private var dragOffset: CGFloat = 0

    private static let autoAdvanceSeconds: Double = 5.0
    private static let tickInterval: Double = 1.0 / 30.0 // 30 fps

    /// The 3 scan images (front/side/back) with labels.
    private var pages: [(image: UIImage?, label: String)] {
        [
            (snapshot.frontImage, "FRONT"),
            (snapshot.sideImage, "SIDE"),
            (snapshot.backImage, "BACK"),
        ]
    }

    /// Only count pages that have an actual image.
    private var availableCount: Int {
        pages.filter { $0.image != nil }.count
    }

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            // Photo
            if let image = pages[currentIndex].image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .id(currentIndex)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.3))
                    Text("No \(pages[currentIndex].label.lowercased()) photo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            // Tap zones (left / right)
            HStack(spacing: 0) {
                // Left tap — go back
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { goBack() }
                    .frame(maxWidth: .infinity)

                // Right tap — go forward
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { goForward() }
                    .frame(maxWidth: .infinity)
            }
            .ignoresSafeArea()

            // Top bar + info overlay
            VStack(spacing: 0) {
                // Progress bars
                progressBars
                    .padding(.horizontal, 8)
                    .padding(.top, 54)

                // Header: close button + date + score
                headerRow
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                Spacer()

                // Bottom label
                VStack(spacing: 6) {
                    Text(pages[currentIndex].label)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .tracking(2)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial.opacity(0.5))
                        .clipShape(Capsule())

                    Text("\(currentIndex + 1) of \(pages.count)")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.bottom, 60)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .updating($dragOffset) { value, state, _ in
                    if value.translation.height > 0 {
                        state = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismiss()
                    }
                }
        )
        .offset(y: dragOffset * 0.4)
        .animation(.interactiveSpring(), value: dragOffset)
        .onAppear { startAutoAdvance() }
        .onDisappear { tickTimer?.invalidate() }
        .statusBarHidden()
    }

    // MARK: - Progress Bars

    private var progressBars: some View {
        HStack(spacing: 4) {
            ForEach(0..<pages.count, id: \.self) { i in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(.white.opacity(0.25))

                        // Fill
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(.white)
                            .frame(width: barWidth(for: i, totalWidth: geo.size.width))
                    }
                }
                .frame(height: 3)
            }
        }
    }

    private func barWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        if index < currentIndex {
            return totalWidth // fully filled — already seen
        } else if index == currentIndex {
            return totalWidth * barProgress // animating
        } else {
            return 0 // not yet reached
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            // Close
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial.opacity(0.4))
                    .clipShape(Circle())
            }

            Spacer()

            // Date + score
            VStack(alignment: .trailing, spacing: 2) {
                Text(snapshot.formattedDate)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                Text("Score: \(Int(snapshot.score))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.ds_cyan)
            }
        }
    }

    // MARK: - Navigation

    private func goForward() {
        if currentIndex < pages.count - 1 {
            tickTimer?.invalidate()
            barProgress = 0
            currentIndex += 1
            startAutoAdvance()
        } else {
            tickTimer?.invalidate()
            dismiss()
        }
    }

    private func goBack() {
        if currentIndex > 0 {
            tickTimer?.invalidate()
            barProgress = 0
            currentIndex -= 1
            startAutoAdvance()
        }
    }

    // MARK: - Auto-advance Timer
    // Drives barProgress manually at 30fps — no SwiftUI animation to cancel.

    private func startAutoAdvance() {
        tickTimer?.invalidate()
        barProgress = 0

        let increment = CGFloat(Self.tickInterval / Self.autoAdvanceSeconds)

        tickTimer = Timer.scheduledTimer(withTimeInterval: Self.tickInterval, repeats: true) { _ in
            Task { @MainActor in
                barProgress += increment
                if barProgress >= 1.0 {
                    barProgress = 1.0
                    goForward()
                }
            }
        }
    }
}
