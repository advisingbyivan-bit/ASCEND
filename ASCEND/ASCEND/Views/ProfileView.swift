import SwiftUI
import DesignSystem
import IRIS
import Gamification
import Notifications
import Paywall
import Networking
import Persistence

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var scanDay: String = "Sunday"
    @State private var restDay: String = "Wednesday"
    @State private var notificationTime = Date()
    @State private var showDeleteConfirm = false
    @State private var showDeleteFinal = false
    @State private var showExportShare = false
    @State private var showSignOutConfirm = false
    @State private var showCreditStore = false
    #if DEBUG
    @State private var showDesignPreview = false
    @State private var showAPIKeySheet = false
    @State private var apiKeyInput: String = ""
    #endif
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showMedicalDisclaimer = false
    @State private var showWeightEditor = false
    @State private var currentWeightKg: Double = 75
    @State private var exportFileURL: URL?
    @State private var exportError: String?
    @State private var isExporting = false
    @State private var showPhotoPicker = false
    @State private var profileImage: UIImage? = ProfileImageStore.load()

    private let scanDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ds_navy.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DSSpacing.md) {
                        profileHeader
                        statsSection
                        preferencesSection
                        subscriptionSection
                        accountSection
                        appInfoSection
                    }
                    .padding(.bottom, 90)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PROFILE")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_cyan)
                        .tracking(2)
                }
            }
            .onAppear {
                scanDay = appState.scanDay
                restDay = appState.restDay
                loadCurrentWeight()
            }
            .alert("Delete Account", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Yes, Delete Everything", role: .destructive) {
                    showDeleteFinal = true
                }
            } message: {
                Text("This will permanently delete your account, all scans, photos, progress data, and leaderboard entry. This cannot be undone.")
            }
            .alert("Final Confirmation", isPresented: $showDeleteFinal) {
                Button("Cancel", role: .cancel) {}
                Button("DELETE MY ACCOUNT", role: .destructive) {
                    performAccountDeletion()
                }
            } message: {
                Text("Are you absolutely sure? All data will be deleted within 30 days and cannot be recovered.")
            }
            .alert("Sign Out", isPresented: $showSignOutConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    performSignOut()
                }
            } message: {
                Text("You'll need to sign in again to access your data.")
            }
            .alert("Export Error", isPresented: .init(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError ?? "An unknown error occurred while exporting your data.")
            }
            .sheet(isPresented: $showExportShare) {
                if let url = exportFileURL {
                    ShareSheetView(activityItems: [url])
                }
            }
            .sheet(isPresented: $showTerms) {
                TermsOfUseView()
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showMedicalDisclaimer) {
                MedicalDisclaimerView()
            }
            #if DEBUG
            .fullScreenCover(isPresented: $showDesignPreview) {
                NavigationStack {
                    DesignSystemPreviewView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showDesignPreview = false }
                                    .foregroundStyle(Color.ds_cyan)
                            }
                        }
                }
            }
            .sheet(isPresented: $showAPIKeySheet) {
                apiKeySheet
            }
            #endif
        }
    }

    // MARK: - Actions

    private func exportUserData() {
        guard !isExporting else { return }
        isExporting = true
        Task { @MainActor in
            do {
                let url = try DataExporter.exportJSON()
                exportFileURL = url
                showExportShare = true
            } catch {
                exportError = error.localizedDescription
            }
            isExporting = false
        }
    }

    private func performAccountDeletion() {
        appState.deleteAllData()
        hasCompletedOnboarding = false
    }

    private func performSignOut() {
        // Clear user identity keys from UserDefaults
        let keysToRemove = [
            "apple_user_id",
            "ascend_streak",
            "ascend_longest_streak",
            "ascend_diamonds",
            "ascend_last_scan"
        ]
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        hasCompletedOnboarding = false
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: DSSpacing.sm) {
            // Profile picture — tap to change
            Button {
                showPhotoPicker = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 88, height: 88)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.ds_cyan.opacity(0.4), lineWidth: 2)
                            )
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.ds_cyan.opacity(0.15))
                                .frame(width: 88, height: 88)
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(Color.ds_cyan)
                        }
                    }

                    // Edit badge
                    ZStack {
                        Circle()
                            .fill(Color.ds_cyan)
                            .frame(width: 26, height: 26)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.ds_navy)
                    }
                    .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)

            Text(appState.displayName.isEmpty ? "You" : appState.displayName)
                .font(DSFont.sectionTitle)
                .foregroundStyle(Color.ds_textPrimary)

            Text(memberSinceText)
                .font(DSFont.caption)
                .foregroundStyle(Color.ds_textSecondary)

            HStack(spacing: DSSpacing.lg) {
                profileStat(value: "\(appState.totalScans)", label: "Scans")
                dividerLine
                profileStat(value: "\(appState.currentStreak)", label: "Streak")
                dividerLine
                profileStat(value: "\(appState.totalDiamonds)", label: "Diamonds")
            }
            .padding(.top, DSSpacing.xs)
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
        .padding(.top, DSSpacing.sm)
        .sheet(isPresented: $showPhotoPicker) {
            ProfileImagePicker { image in
                profileImage = image
                ProfileImageStore.save(image)
            }
        }
    }

    private var memberSinceText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Joined \(formatter.localizedString(for: appState.memberSince, relativeTo: Date()))"
    }

    private func profileStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(DSFont.statSmall)
                .foregroundStyle(Color.ds_cyan)
            Text(label)
                .font(DSFont.micro)
                .foregroundStyle(Color.ds_textSecondary)
        }
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.ds_charcoal)
            .frame(width: 1, height: 30)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(spacing: DSSpacing.xs) {
            sectionHeader("STATS")
            settingsRow(icon: "trophy.fill", label: "Best Streak", value: "\(appState.longestStreak) days", color: Color.ds_yellow)
            settingsRow(icon: "chart.line.uptrend.xyaxis", label: "Best Score", value: bestScoreText, color: Color.ds_green)
            settingsRow(icon: "viewfinder", label: "Total Scans", value: "\(appState.totalScans)", color: Color.ds_cyan)

            // Scan credits with buy button
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Color.ds_cyan)
                    .frame(width: 24)
                Text("Scan Credits")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textPrimary)
                Spacer()
                Button {
                    showCreditStore = true
                } label: {
                    HStack(spacing: 4) {
                        Text(appState.scanCreditsDisplay)
                            .font(DSFont.captionBold)
                            .foregroundStyle(Color.ds_cyan)
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.ds_cyan)
                    }
                }
                .buttonStyle(.plain)
            }

            settingsRow(icon: "star.fill", label: "Badges Earned", value: "\(appState.earnedBadgeCount)", color: Color.ds_purple)
            settingsRow(icon: "clock.fill", label: "Member Since", value: memberDateShort, color: Color.ds_textSecondary)
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
        .sheet(isPresented: $showCreditStore) {
            CreditStoreView()
                .environment(appState)
        }
    }

    private var bestScoreText: String {
        if let score = appState.latestDiagnosis?.overallScore {
            return "\(Int(score))"
        }
        return "--"
    }

    private var memberDateShort: String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: appState.memberSince)
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(spacing: DSSpacing.xs) {
            sectionHeader("PREFERENCES")

            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Color.ds_cyan)
                    .frame(width: 24)
                Text("Scan Day")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textPrimary)
                Spacer()
                Picker("", selection: $scanDay) {
                    ForEach(scanDays, id: \.self) { Text($0).tag($0) }
                }
                .tint(Color.ds_cyan)
            }

            Divider().background(Color.ds_charcoal)

            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundStyle(Color.ds_purple)
                    .frame(width: 24)
                Text("Rest Day")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textPrimary)
                Spacer()
                Picker("", selection: $restDay) {
                    ForEach(scanDays, id: \.self) { Text($0).tag($0) }
                }
                .tint(Color.ds_cyan)
            }

            Divider().background(Color.ds_charcoal)

            HStack {
                Image(systemName: "bell.fill")
                    .foregroundStyle(Color.ds_yellow)
                    .frame(width: 24)
                Text("Notification Time")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textPrimary)
                Spacer()
                DatePicker("", selection: $notificationTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .tint(Color.ds_cyan)
            }

            Divider().background(Color.ds_charcoal)

            Button { showWeightEditor = true } label: {
                HStack(spacing: DSSpacing.sm) {
                    Image(systemName: "scalemass.fill")
                        .foregroundStyle(Color.ds_green)
                        .frame(width: 24)
                    Text("Current Weight")
                        .font(DSFont.body)
                        .foregroundStyle(Color.ds_textPrimary)
                    Spacer()
                    Text(String(format: "%.0f kg", currentWeightKg))
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.ds_textSecondary)
                }
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
        .onChange(of: scanDay) { _, newDay in
            rescheduleNotifications(scanDay: newDay)
        }
        .sheet(isPresented: $showWeightEditor) {
            WeightCheckInSheet(
                onConfirm: { loadCurrentWeight() },
                onSkip: {}
            )
            .environment(appState)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private func loadCurrentWeight() {
        if let profile = try? DataStore.shared.fetchProfile() {
            currentWeightKg = profile.weightKg
        }
    }

    private func rescheduleNotifications(scanDay: String) {
        let weekdayInt = weekdayNumber(from: scanDay)
        let restWeekdayInt = weekdayNumber(from: restDay)
        let hour = Calendar.current.component(.hour, from: notificationTime)
        NotificationScheduler.shared.cancelAll()
        NotificationScheduler.shared.scheduleWeeklyScanReminder(weekday: weekdayInt, hour: hour, minute: 0)
        NotificationScheduler.shared.scheduleMidWeekCheckIn(hour: hour, weekday: restWeekdayInt)
    }

    private func weekdayNumber(from name: String) -> Int {
        switch name.lowercased() {
        case "sunday": return 1
        case "monday": return 2
        case "tuesday": return 3
        case "wednesday": return 4
        case "thursday": return 5
        case "friday": return 6
        case "saturday": return 7
        default: return 1
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        VStack(spacing: DSSpacing.xs) {
            sectionHeader("SUBSCRIPTION")

            accountRow(icon: "crown.fill", label: "Manage Subscription", color: Color.ds_gold) {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            }

            Divider().background(Color.ds_charcoal)

            accountRow(icon: "arrow.clockwise", label: "Restore Purchases", color: Color.ds_cyan) {
                Task {
                    let _ = await SubscriptionManager.shared.restorePurchases()
                }
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(spacing: DSSpacing.xs) {
            sectionHeader("ACCOUNT")

            accountRow(icon: "arrow.down.circle.fill", label: isExporting ? "Exporting..." : "Export My Data", color: Color.ds_textSecondary) {
                exportUserData()
            }

            Divider().background(Color.ds_charcoal)

            accountRow(icon: "rectangle.portrait.and.arrow.right.fill", label: "Sign Out", color: Color.ds_textSecondary) {
                showSignOutConfirm = true
            }

            Divider().background(Color.ds_charcoal)

            accountRow(icon: "trash.fill", label: "Delete Account", color: Color.ds_red) {
                showDeleteConfirm = true
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
    }

    private func accountRow(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 24)
                Text(label)
                    .font(DSFont.body)
                    .foregroundStyle(label == "Delete Account" ? Color.ds_red : Color.ds_textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.ds_textSecondary)
            }
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(spacing: DSSpacing.sm) {
            #if DEBUG
            debugSection
            #endif

            IRISSphereView(state: .idle, size: .badge)

            Text("ASCEND")
                .font(DSFont.captionBold)
                .foregroundStyle(Color.ds_textSecondary)
                .tracking(2)

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(DSFont.micro)
                .foregroundStyle(Color.ds_textSecondary.opacity(0.6))
                #if DEBUG
                .onTapGesture(count: 5) {
                    showDesignPreview = true
                }
                #endif

            HStack(spacing: DSSpacing.lg) {
                linkButton("Privacy Policy")
                linkButton("Terms of Service")
            }

            Button("Medical Disclaimer") {
                showMedicalDisclaimer = true
            }
            .font(DSFont.micro)
            .foregroundStyle(Color.ds_cyan.opacity(0.6))

            Text("ASCEND is not a medical device. AI feedback is for fitness guidance only. Consult a healthcare professional for medical advice.")
                .font(DSFont.micro)
                .foregroundStyle(Color.ds_textSecondary.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, DSSpacing.md)
        }
        .padding(.vertical, DSSpacing.md)
        .padding(.horizontal, DSSpacing.screenPadding)
    }

    // MARK: - Debug Section (DEBUG only)
    #if DEBUG
    private var debugSection: some View {
        VStack(spacing: DSSpacing.xs) {
            sectionHeader("DEVELOPER")

            // API Key status
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: "key.fill")
                    .foregroundStyle(APIKeyManager.isConfigured ? Color.ds_green : Color.ds_red)
                    .frame(width: 24)
                Text("Claude API Key")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textPrimary)
                Spacer()
                Button {
                    apiKeyInput = APIKeyManager.currentKey() ?? ""
                    showAPIKeySheet = true
                } label: {
                    Text(APIKeyManager.isConfigured ? "Configured" : "Set Key")
                        .font(DSFont.captionBold)
                        .foregroundStyle(APIKeyManager.isConfigured ? Color.ds_green : Color.ds_cyan)
                }
                .buttonStyle(.plain)
            }

            Divider().background(Color.ds_charcoal)

            // Add debug credits
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.ds_cyan)
                    .frame(width: 24)
                Text("Add 5 Debug Credits")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textPrimary)
                Spacer()
                Button {
                    ScanCreditManager.shared.addCredits(5, source: .other)
                    DSHaptic.success()
                } label: {
                    Text("ADD")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_cyan)
                }
                .buttonStyle(.plain)
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
    }

    private var apiKeySheet: some View {
        NavigationStack {
            ZStack {
                Color.ds_navy.ignoresSafeArea()

                VStack(spacing: DSSpacing.md) {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Anthropic API Key")
                            .font(DSFont.cardTitle)
                            .foregroundStyle(Color.ds_textPrimary)

                        Text("Enter your API key to enable real AI body analysis. Get one at console.anthropic.com")
                            .font(DSFont.caption)
                            .foregroundStyle(Color.ds_textSecondary)

                        TextField("sk-ant-...", text: $apiKeyInput)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13, design: .monospaced))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding(.top, DSSpacing.xs)
                    }

                    HStack(spacing: DSSpacing.sm) {
                        Button("Remove") {
                            APIKeyManager.removeKey()
                            apiKeyInput = ""
                            showAPIKeySheet = false
                        }
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.ds_red.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        Button("Save") {
                            APIKeyManager.setKey(apiKeyInput)
                            showAPIKeySheet = false
                        }
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_navy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.ds_cyan)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Spacer()
                }
                .padding(DSSpacing.screenPadding)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("API KEY")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_cyan)
                        .tracking(2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showAPIKeySheet = false }
                        .foregroundStyle(Color.ds_cyan)
                }
            }
        }
        .presentationDetents([.medium])
    }
    #endif

    private func linkButton(_ title: String) -> some View {
        Button(title) {
            if title == "Privacy Policy" {
                showPrivacy = true
            } else {
                showTerms = true
            }
        }
        .font(DSFont.micro)
        .foregroundStyle(Color.ds_cyan.opacity(0.6))
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(DSFont.captionBold)
                .foregroundStyle(Color.ds_cyan)
                .tracking(2)
            Spacer()
        }
    }

    private func settingsRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
                .font(DSFont.body)
                .foregroundStyle(Color.ds_textPrimary)
            Spacer()
            Text(value)
                .font(DSFont.captionBold)
                .foregroundStyle(Color.ds_textSecondary)
        }
    }
}

// MARK: - Share Sheet (UIKit bridge)

private struct ShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Profile Image Picker

private struct ProfileImagePicker: UIViewControllerRepresentable {
    let onPick: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPick: (UIImage) -> Void
        init(onPick: @escaping (UIImage) -> Void) { self.onPick = onPick }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let edited = info[.editedImage] as? UIImage {
                onPick(edited)
            } else if let original = info[.originalImage] as? UIImage {
                onPick(original)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Profile Image Store

enum ProfileImageStore {
    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_photo.jpg")
    }

    static func save(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: fileURL)
    }

    static func load() -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
}
