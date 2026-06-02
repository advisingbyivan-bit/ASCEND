import SwiftUI

// MARK: - Liquid Glass ViewModifier

/// True liquid glass: let the frosted material do the heavy lifting.
/// Minimal overlays so the background blur actually shows through.
/// Optimized — 2 layers + 1 border + 1 shadow (was 6 + 2).
public struct DSGlass: ViewModifier {
    let tint: Color
    let tintOpacity: Double
    let radius: CGFloat
    let border: Bool

    public init(
        tint: Color = .clear,
        tintOpacity: Double = 0.1,
        radius: CGFloat = DSSpacing.cardRadius,
        border: Bool = true
    ) {
        self.tint = tint
        self.tintOpacity = tintOpacity
        self.radius = radius
        self.border = border
    }

    public func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Layer 1: Material blur — the real glass effect
                    RoundedRectangle(cornerRadius: radius)
                        .fill(.thinMaterial)

                    // Layer 2: Natural light refraction — barely-there tint
                    // that mimics how light passes through tinted glass.
                    // Whisper of white at top (overhead light), hint of cyan body.
                    RoundedRectangle(cornerRadius: radius)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.08), location: 0),
                                    .init(color: Color.white.opacity(0.03), location: 0.05),
                                    .init(color: Color.ds_cyan.opacity(0.04), location: 0.15),
                                    .init(color: Color.ds_cyan.opacity(0.03), location: 0.5),
                                    .init(color: Color.ds_cyan.opacity(0.02), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Layer 3 (optional): Color tint
                    if tint != .clear {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(tint.opacity(tintOpacity))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: radius))
            // Subtle inner bottom shadow — glass thickness without heaviness
            .overlay {
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.07)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 20)
                }
                .clipShape(RoundedRectangle(cornerRadius: radius))
                .allowsHitTesting(false)
            }
            .overlay {
                if border {
                    // Glass edge — natural light catch, not a drawn border
                    RoundedRectangle(cornerRadius: radius)
                        .stroke(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.28), location: 0),
                                    .init(color: Color.white.opacity(0.10), location: 0.3),
                                    .init(color: Color.ds_cyan.opacity(0.06), location: 0.7),
                                    .init(color: Color.ds_cyan.opacity(0.10), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
            }
            // Soft ambient glow — glass catching light, not emitting it
            .shadow(color: Color.ds_cyan.opacity(0.06), radius: 10, y: 0)
    }
}

// MARK: - Convenience extensions

public extension View {
    func dsGlass(radius: CGFloat = DSSpacing.cardRadius, border: Bool = true) -> some View {
        modifier(DSGlass(radius: radius, border: border))
    }

    func dsGlass(tint: Color, tintOpacity: Double = 0.1, radius: CGFloat = DSSpacing.cardRadius) -> some View {
        modifier(DSGlass(tint: tint, tintOpacity: tintOpacity, radius: radius))
    }
}

// MARK: - Glass Card

public struct DSGlassCard<Content: View>: View {
    let tint: Color
    let content: Content

    public init(tint: Color = .clear, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    public var body: some View {
        content
            .padding(DSSpacing.md)
            .dsGlass(tint: tint)
    }
}

// MARK: - Glass Button Styles

/// Primary action button — frosted cyan glass with glow.
public struct DSGlassPrimaryButton: View {
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
                RoundedRectangle(cornerRadius: DSSpacing.buttonRadius)
                    .fill(.thinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: DSSpacing.buttonRadius)
                            .fill(Color.ds_cyan.opacity(0.20))
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.buttonRadius))
            .overlay {
                RoundedRectangle(cornerRadius: DSSpacing.buttonRadius)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.22), location: 0),
                                .init(color: Color.ds_cyan.opacity(0.08), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: Color.ds_cyan.opacity(0.08), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

/// Secondary button — frosted glass with cyan text.
public struct DSGlassSecondaryButton: View {
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
