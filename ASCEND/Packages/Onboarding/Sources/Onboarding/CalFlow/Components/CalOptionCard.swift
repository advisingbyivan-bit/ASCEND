import SwiftUI
import DesignSystem

struct CalOptionCard: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.ds_navy : Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.ds_cyan : Color.ds_textSecondary)
                }

                Text(label)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(isSelected ? Color.ds_textPrimary : Color.ds_textPrimary.opacity(0.9))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.ds_cyan)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 72)
            .background(
                isSelected
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [Color.ds_cyan.opacity(0.15), Color.ds_cyan.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    : AnyShapeStyle(Color.ds_charcoal)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.ds_cyan.opacity(0.6) : Color.ds_cardBorder, lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: isSelected ? Color.ds_cyan.opacity(0.2) : .clear, radius: 8)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
