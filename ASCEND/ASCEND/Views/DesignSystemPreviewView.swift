#if DEBUG
import SwiftUI
import DesignSystem
import IRIS

struct DesignSystemPreviewView: View {
    @State private var irisState: IRISState = .idle
    @State private var showConfetti = false
    @State private var ringProgress = 0.0

    var body: some View {
        NavigationStack {
            ZStack {
                DSAmbientBackground()

                ScrollView {
                    VStack(spacing: DSSpacing.xl) {
                        logoSection
                        irisSection
                        typographySection
                        buttonsSection
                        cardsSection
                        glowSection
                        progressSection
                        typewriterSection
                    }
                    .padding(.horizontal, DSSpacing.screenPadding)
                    .padding(.bottom, DSSpacing.huge)
                }
            }
            .navigationTitle("Design System")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var logoSection: some View {
        VStack(spacing: DSSpacing.md) {
            Text("ASCEND Logo")
                .font(DSFont.sectionTitle)
                .foregroundStyle(Color.ds_textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ASCENDLogoView(size: 160)
                .frame(height: 180)

            HStack(spacing: DSSpacing.xl) {
                ASCENDLogoView(size: 60)
                ASCENDLogoView(size: 40)
                ASCENDLogoView(size: 28)
            }
        }
    }

    private var irisSection: some View {
        VStack(spacing: DSSpacing.md) {
            Text("IRIS Sphere")
                .font(DSFont.sectionTitle)
                .foregroundStyle(Color.ds_textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            IRISSphereView(state: irisState, size: .full)
                .frame(height: 260)

            HStack(spacing: DSSpacing.xs) {
                ForEach(Array(irisStates.enumerated()), id: \.offset) { _, item in
                    Button(item.label) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            irisState = item.state
                        }
                    }
                    .font(DSFont.micro)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(irisState == item.state ? Color.ds_cyan.opacity(0.2) : Color.ds_charcoal)
                    .foregroundStyle(irisState == item.state ? Color.ds_cyan : Color.ds_textSecondary)
                    .clipShape(Capsule())
                }
            }

            HStack(spacing: DSSpacing.md) {
                IRISSphereView(state: irisState, size: .dashboard)
                IRISSphereView(state: irisState, size: .notification)
                IRISSphereView(state: irisState, size: .badge)
                IRISSphereView(state: irisState, size: .tabIcon)
            }
        }
    }

    private var irisStates: [(label: String, state: IRISState)] {
        [
            ("Idle", .idle),
            ("Listen", .listening),
            ("Think", .processing),
            ("Speak", .speaking),
            ("Win", .celebration),
            ("Warn", .warning),
        ]
    }

    private var typographySection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("Typography")
                .font(DSFont.sectionTitle)
                .foregroundStyle(Color.ds_textPrimary)

            Text("Hero Title").font(DSFont.heroTitle).foregroundStyle(Color.ds_textPrimary)
            Text("Screen Title").font(DSFont.screenTitle).foregroundStyle(Color.ds_textPrimary)
            Text("Section Title").font(DSFont.sectionTitle).foregroundStyle(Color.ds_textPrimary)
            Text("Card Title").font(DSFont.cardTitle).foregroundStyle(Color.ds_textPrimary)
            Text("Body Text").font(DSFont.body).foregroundStyle(Color.ds_textSecondary)
            Text("87%").font(DSFont.stat).foregroundStyle(Color.ds_cyan)
            Text("12.5").font(DSFont.statSmall).foregroundStyle(Color.ds_cyan)
            Text("Caption").font(DSFont.caption).foregroundStyle(Color.ds_textSecondary)
            Text("MICRO").font(DSFont.micro).foregroundStyle(Color.ds_textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var buttonsSection: some View {
        VStack(spacing: DSSpacing.sm) {
            Text("Buttons")
                .font(DSFont.sectionTitle)
                .foregroundStyle(Color.ds_textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            DSPrimaryButton("Start Body Scan", icon: "viewfinder") {
                DSHaptic.medium()
            }

            DSSecondaryButton("View Progress", icon: "chart.line.uptrend.xyaxis") {}

            DSPrimaryButton("Loading...", isLoading: true) {}

            DSDisabledButton("Locked Feature")
        }
    }

    private var cardsSection: some View {
        VStack(spacing: DSSpacing.sm) {
            Text("Cards")
                .font(DSFont.sectionTitle)
                .foregroundStyle(Color.ds_textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            DSCard {
                HStack {
                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                        Text("Focus Area")
                            .font(DSFont.captionBold)
                            .foregroundStyle(Color.ds_textSecondary)
                        Text("Shoulders")
                            .font(DSFont.cardTitle)
                            .foregroundStyle(Color.ds_textPrimary)
                        Text("+12% this week")
                            .font(DSFont.statSmall)
                            .foregroundStyle(Color.ds_green)
                    }
                    Spacer()
                    Image(systemName: "figure.arms.open")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.ds_cyan)
                        .dsGlow(color: .ds_cyan, radius: 8, intensity: 0.4)
                }
            }

            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text("IRIS Says")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_textSecondary)
                    Text("Your shoulders are 23% stronger than last month. Keep pushing.")
                        .font(DSFont.body)
                        .foregroundStyle(Color.ds_textPrimary)
                }
            }
        }
    }

    private var glowSection: some View {
        VStack(spacing: DSSpacing.sm) {
            Text("Glow Effects")
                .font(DSFont.sectionTitle)
                .foregroundStyle(Color.ds_textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: DSSpacing.xl) {
                Circle()
                    .fill(Color.ds_cyan)
                    .frame(width: 40, height: 40)
                    .dsGlow(color: .ds_cyan, radius: 12)

                Circle()
                    .fill(Color.ds_purple)
                    .frame(width: 40, height: 40)
                    .dsGlow(color: .ds_purple, radius: 12)

                Circle()
                    .fill(Color.ds_green)
                    .frame(width: 40, height: 40)
                    .dsGlow(color: .ds_green, radius: 12)

                Circle()
                    .fill(Color.ds_red)
                    .frame(width: 40, height: 40)
                    .dsGlow(color: .ds_red, radius: 12)

                Circle()
                    .fill(Color.ds_yellow)
                    .frame(width: 40, height: 40)
                    .dsGlow(color: .ds_yellow, radius: 12)
            }

            Circle()
                .fill(Color.ds_cyan)
                .frame(width: 60, height: 60)
                .dsPulsingGlow(color: .ds_cyan, radius: 16)
                .padding(.top, DSSpacing.sm)
        }
    }

    private var progressSection: some View {
        VStack(spacing: DSSpacing.sm) {
            Text("Progress Rings")
                .font(DSFont.sectionTitle)
                .foregroundStyle(Color.ds_textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: DSSpacing.xxl) {
                DSProgressRing(progress: 0.87, size: 80)
                DSProgressRing(progress: 0.45, size: 60, progressColor: .ds_yellow)
                DSProgressRing(progress: 0.2, size: 50, progressColor: .ds_red)
                DSProgressRing(progress: 1.0, size: 50, progressColor: .ds_green)
            }
        }
    }

    private var typewriterSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("Typewriter Text")
                .font(DSFont.sectionTitle)
                .foregroundStyle(Color.ds_textPrimary)

            DSCard {
                DSTypewriterText("I'm IRIS. I see everything. You won't escape me.")
            }
        }
    }
}
#endif
