import SwiftUI
import DesignSystem
import Persistence

struct WeightCheckInSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var weightKg: Double = 75
    @State private var useLbs: Bool = false

    let onConfirm: () -> Void
    let onSkip: () -> Void

    private var displayWeight: Int {
        useLbs ? Int(round(weightKg * 2.20462)) : Int(round(weightKg))
    }

    private var unitLabel: String {
        useLbs ? "lbs" : "kg"
    }

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            Spacer().frame(height: DSSpacing.sm)

            Image(systemName: "scalemass.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.ds_cyan)

            Text("Quick Weight Check-in")
                .font(DSFont.sectionTitle)
                .foregroundStyle(Color.ds_textPrimary)

            Text("Keep your analysis accurate with your latest weight.")
                .font(DSFont.caption)
                .foregroundStyle(Color.ds_textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DSSpacing.lg)

            HStack(spacing: DSSpacing.xl) {
                stepperButton(systemName: "minus") {
                    adjust(by: useLbs ? -1.0 / 2.20462 : -1)
                }

                VStack(spacing: DSSpacing.xxs) {
                    Text("\(displayWeight)")
                        .font(DSFont.stat)
                        .foregroundStyle(Color.ds_textPrimary)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.15), value: displayWeight)
                    Text(unitLabel)
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_textSecondary)
                }

                stepperButton(systemName: "plus") {
                    adjust(by: useLbs ? 1.0 / 2.20462 : 1)
                }
            }
            .padding(.vertical, DSSpacing.sm)

            Button {
                useLbs.toggle()
            } label: {
                Text("Switch to \(useLbs ? "kg" : "lbs")")
                    .font(DSFont.caption)
                    .foregroundStyle(Color.ds_cyan.opacity(0.7))
            }

            Button {
                DSHaptic.success()
                appState.updateWeight(weightKg)
                dismiss()
                onConfirm()
            } label: {
                Text("Confirm")
                    .font(DSFont.bodyBold)
                    .foregroundStyle(Color.ds_navy)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.ds_cyan)
                    .clipShape(RoundedRectangle(cornerRadius: DSSpacing.buttonRadius))
            }
            .padding(.horizontal, DSSpacing.screenPadding)

            Button {
                dismiss()
                onSkip()
            } label: {
                Text("Skip")
                    .font(DSFont.caption)
                    .foregroundStyle(Color.ds_textSecondary)
            }

            Spacer().frame(height: DSSpacing.xs)
        }
        .padding(.horizontal, DSSpacing.screenPadding)
        .background(Color.ds_navy.ignoresSafeArea())
        .onAppear {
            if let profile = try? DataStore.shared.fetchProfile() {
                weightKg = profile.weightKg
            }
        }
    }

    private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            DSHaptic.selection()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.ds_cyan)
                .frame(width: 48, height: 48)
                .background(Color.ds_cyan.opacity(0.12))
                .clipShape(Circle())
        }
    }

    private func adjust(by delta: Double) {
        let newWeight = weightKg + delta
        weightKg = max(30, min(250, newWeight))
    }

    static var shouldShow: Bool {
        let lastUpdate = UserDefaults.standard.double(forKey: "ascend_last_weight_update")
        guard lastUpdate > 0 else { return true }
        let lastDate = Date(timeIntervalSince1970: lastUpdate)
        let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSince >= 7
    }
}
