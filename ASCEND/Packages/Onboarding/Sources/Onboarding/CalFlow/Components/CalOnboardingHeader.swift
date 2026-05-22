import SwiftUI
import DesignSystem

struct CalOnboardingHeader: View {
    let progress: Double
    let showsBack: Bool
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if showsBack {
                Button(action: onBack) {
                    ZStack {
                        Circle()
                            .fill(Color.ds_charcoal)
                            .frame(width: 44, height: 44)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.ds_textPrimary)
                    }
                }
                .buttonStyle(.plain)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.ds_charcoal)
                        .frame(height: 3)

                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(
                            LinearGradient(
                                colors: [Color.ds_cyan.opacity(0.7), Color.ds_cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 3)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, DSSpacing.screenPadding)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}
