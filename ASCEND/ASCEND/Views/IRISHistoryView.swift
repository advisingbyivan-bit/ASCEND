import SwiftUI
import DesignSystem
import BodyModel3D

/// Scrollable feed of every IRIS verdict from past scans.
/// Accessible from the Scan tab toolbar (clock icon).
struct IRISHistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DSAnimatedBackground()

                DSFloatingParticles(count: 8, colors: [Color.ds_purple.opacity(0.2), Color.ds_cyan.opacity(0.1)])
                    .ignoresSafeArea()

                if scansWithVerdicts.isEmpty {
                    emptyState
                } else {
                    verdictList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("IRIS HISTORY")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_cyan)
                        .tracking(2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(DSFont.body)
                        .foregroundStyle(Color.ds_cyan)
                }
            }
        }
    }

    // Only show scans that have an IRIS message
    private var scansWithVerdicts: [ScanSnapshot] {
        appState.scanHistory.filter { $0.irisMessage != nil && !($0.irisMessage?.isEmpty ?? true) }
    }

    private var emptyState: some View {
        VStack(spacing: DSSpacing.lg) {
            Spacer()
            Image(systemName: "eye.slash")
                .font(.system(size: 48))
                .foregroundStyle(Color.ds_textSecondary.opacity(0.3))
            VStack(spacing: DSSpacing.xs) {
                Text("No IRIS Verdicts Yet")
                    .font(DSFont.cardTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                Text("Complete a scan to get your first IRIS analysis.")
                    .font(DSFont.caption)
                    .foregroundStyle(Color.ds_textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.horizontal, DSSpacing.screenPadding)
    }

    private var verdictList: some View {
        ScrollView {
            LazyVStack(spacing: DSSpacing.md) {
                ForEach(scansWithVerdicts) { scan in
                    verdictCard(scan)
                }
            }
            .padding(.horizontal, DSSpacing.screenPadding)
            .padding(.top, DSSpacing.md)
            .padding(.bottom, 100)
        }
    }

    private func verdictCard(_ scan: ScanSnapshot) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            // Header: date + score
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.ds_cyan)
                    Text(fullDate(scan.date))
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_textPrimary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("\(Int(scan.score))")
                        .font(DSFont.statSmall)
                        .foregroundStyle(Color.ds_cyan)
                    Text("/ 100")
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary)
                }
            }

            // IRIS message
            if let message = scan.irisMessage {
                Text(message)
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Zone summary row
            if let zones = scan.zoneData {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(zones, id: \.zone) { zone in
                            let status = ZoneStatus.from(zone.status) ?? .moderate
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(status.color)
                                    .frame(width: 6, height: 6)
                                Text(zone.zone.capitalized)
                                    .font(DSFont.micro)
                                    .foregroundStyle(Color.ds_textSecondary)
                                if zone.delta != 0 {
                                    Text(zone.delta > 0 ? "+\(Int(zone.delta))%" : "\(Int(zone.delta))%")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(zone.delta > 0 ? Color.ds_green : Color.ds_red)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(status.color.opacity(0.08))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .dsCard()
    }

    private func fullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
