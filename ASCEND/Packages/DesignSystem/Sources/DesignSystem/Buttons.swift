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
                        .tint(.ds_navy)
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
            .background(Color.ds_cyan)
            .foregroundStyle(Color.ds_navy)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.buttonRadius))
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
            .background(Color.clear)
            .foregroundStyle(Color.ds_cyan)
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.buttonRadius)
                    .stroke(Color.ds_cyan.opacity(0.5), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.buttonRadius))
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
            .background(Color.ds_charcoal.opacity(0.5))
            .foregroundStyle(Color.ds_textSecondary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.buttonRadius))
    }
}
