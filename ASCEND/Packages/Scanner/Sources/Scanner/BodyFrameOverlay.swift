import SwiftUI
import DesignSystem

struct BodyFrameOverlay: View {
    let isInFrame: Bool

    var body: some View {
        GeometryReader { _ in
            ZStack {
                // Subtle darkened edges only (no guide lines)
                Color.black.opacity(0.15)
                    .ignoresSafeArea()

                // Status pill
                VStack {
                    Spacer()

                    HStack(spacing: 6) {
                        Circle()
                            .fill(isInFrame ? Color.ds_green : Color.ds_red)
                            .frame(width: 8, height: 8)
                        Text(isInFrame ? "IN FRAME" : "STEP BACK")
                            .font(DSFont.captionBold)
                            .foregroundStyle(isInFrame ? Color.ds_green : Color.ds_red)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(.bottom, 180)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
