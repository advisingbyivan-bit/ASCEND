import SwiftUI
import DesignSystem

public struct DiamondCelebrationView: View {
    let milestone: DiamondMilestone
    let onDismiss: () -> Void
    @State private var showContent = false

    public init(milestone: DiamondMilestone, onDismiss: @escaping () -> Void) {
        self.milestone = milestone
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            Color.ds_navy.opacity(0.95).ignoresSafeArea()

            if showContent {
                VStack(spacing: DSSpacing.xl) {
                    Spacer()

                    ZStack {
                        DSConfettiView()
                            .frame(width: 300, height: 300)

                        VStack(spacing: DSSpacing.md) {
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(Color.ds_cyan)
                                .dsPulsingGlow(color: Color.ds_cyan, radius: 20)

                            Text("DIAMOND UNLOCKED")
                                .font(DSFont.captionBold)
                                .foregroundStyle(Color.ds_cyan)
                                .tracking(4)

                            Text(milestone.displayName)
                                .font(DSFont.heroTitle)
                                .foregroundStyle(Color.ds_textPrimary)

                            Text(milestone.description)
                                .font(DSFont.body)
                                .foregroundStyle(Color.ds_textSecondary)
                        }
                    }

                    Spacer()

                    DSPrimaryButton("Continue", icon: "arrow.right") {
                        onDismiss()
                    }
                    .padding(.horizontal, DSSpacing.screenPadding)
                    .padding(.bottom, DSSpacing.xl)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            DSHaptic.diamondUnlock()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                showContent = true
            }
        }
    }
}
