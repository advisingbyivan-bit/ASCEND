import SwiftUI

public struct DSPrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void

    public init(_ title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(DSFont.bodyBold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(.white)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: DSSpacing.buttonRadius)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: DSSpacing.buttonRadius)
                        .fill(Color.ds_cyan.opacity(0.35))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.buttonRadius))
            .overlay {
                RoundedRectangle(cornerRadius: DSSpacing.buttonRadius)
                    .stroke(
                        LinearGradient(
                            colors: [Color.ds_cyan.opacity(0.6), Color.ds_cyan.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: Color.ds_cyan.opacity(0.2), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

public struct DSSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    public init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(DSFont.bodyBold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(Color.ds_cyan)
            .dsGlass(tint: .ds_cyan, tintOpacity: 0.05, radius: DSSpacing.buttonRadius)
        }
        .buttonStyle(.plain)
    }
}

public struct DSDisabledButton: View {
    let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .font(DSFont.bodyBold)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(Color.ds_textSecondary.opacity(0.5))
            .dsGlass(radius: DSSpacing.buttonRadius, border: false)
            .opacity(0.6)
    }
}
