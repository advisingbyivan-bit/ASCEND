import SwiftUI
import DesignSystem

// MARK: - Terms of Use

struct TermsOfUseView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        sectionHeader("1. Acceptance of Terms")
                        sectionBody("By downloading, installing, or using ASCEND (\"the App\"), you agree to be bound by these Terms of Use. If you do not agree to these terms, do not use the App.")

                        sectionHeader("2. Description of Service")
                        sectionBody("ASCEND is a body transformation tracking application that uses AI-powered visual analysis to provide fitness diagnostics, progress tracking, and motivational coaching. ASCEND is NOT a medical device and does not provide medical advice, diagnosis, or treatment.")

                        sectionHeader("3. Eligibility")
                        sectionBody("You must be at least 17 years old to use ASCEND. By using the App, you represent and warrant that you meet this age requirement.")

                        sectionHeader("4. Account Registration")
                        sectionBody("You may create an account using Sign in with Apple, Google Sign-In, or email/password. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.")

                        sectionHeader("5. Subscriptions & Payments")
                        sectionBody("""
                        ASCEND offers premium features through auto-renewable subscriptions managed by Apple's In-App Purchase system.

                        • Free Trial: 3-day free trial available for new subscribers.
                        • Yearly Plan: $29.99/year after trial.
                        • Monthly Plan: $9.99/month after trial.
                        • Payment is charged to your Apple ID account at confirmation of purchase.
                        • Subscription auto-renews unless cancelled at least 24 hours before the end of the current period.
                        • Manage or cancel subscriptions in Settings > Apple ID > Subscriptions.
                        """)
                    }

                    Group {
                        sectionHeader("6. User Content")
                        sectionBody("You retain ownership of photos and data you submit to ASCEND. By using the App, you grant ASCEND a limited license to process your photos for AI analysis purposes only. Your photos are encrypted and never shared with third parties.")

                        sectionHeader("7. AI Diagnostics Disclaimer")
                        sectionBody("AI-generated scores, feedback, and recommendations are for fitness guidance only. They should not replace professional medical advice. Always consult a healthcare professional before making significant changes to your fitness or nutrition regimen.")

                        sectionHeader("8. Prohibited Conduct")
                        sectionBody("""
                        You agree not to:
                        • Use the App for any unlawful purpose.
                        • Upload inappropriate, offensive, or illegal content.
                        • Attempt to reverse-engineer, hack, or compromise the App.
                        • Create multiple accounts to manipulate leaderboards or earn duplicate rewards.
                        • Share your account credentials with others.
                        """)

                        sectionHeader("9. Termination")
                        sectionBody("We may suspend or terminate your access to the App at any time for violation of these Terms. You may delete your account at any time through Profile > Account > Delete Account.")

                        sectionHeader("10. Limitation of Liability")
                        sectionBody("ASCEND is provided \"as is\" without warranties of any kind. We are not liable for any injuries, health issues, or damages arising from use of the App or reliance on its AI-generated feedback.")

                        sectionHeader("11. Changes to Terms")
                        sectionBody("We may update these Terms from time to time. Continued use of the App after changes constitutes acceptance of the new Terms.")

                        sectionHeader("12. Contact")
                        sectionBody("For questions about these Terms, contact us at support@ascendapp.us")
                    }

                    Text("Last updated: May 2025")
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary)
                        .padding(.top, 10)
                }
                .padding(20)
            }
            .background(Color.ds_navy)
            .navigationTitle("Terms of Use")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.ds_cyan)
                }
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(DSFont.sectionTitle)
            .foregroundStyle(Color.ds_textPrimary)
    }

    private func sectionBody(_ text: String) -> some View {
        Text(text)
            .font(DSFont.body)
            .foregroundStyle(Color.ds_textSecondary)
            .lineSpacing(4)
    }
}

// MARK: - Privacy Policy

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        sectionHeader("1. Information We Collect")
                        sectionBody("""
                        ASCEND collects the following types of information:

                        • Account Information: Name, email address, Apple ID or Google ID for authentication.
                        • Body Data: Photos taken during body scans (front, side, back views), height, weight, body composition scores.
                        • Fitness Data: Training frequency, body zone assessments, progress metrics, streak data.
                        • Usage Data: App interaction patterns, scan frequency, feature usage (anonymized for analytics).
                        • Subscription Data: Purchase history and subscription status (managed by Apple).
                        """)

                        sectionHeader("2. How We Use Your Information")
                        sectionBody("""
                        • To provide AI-powered body diagnostics and progress tracking.
                        • To generate personalized IRIS coaching messages.
                        • To maintain leaderboards and community features.
                        • To send push notifications (with your permission) for scan reminders, streak updates, and milestones.
                        • To improve the App through anonymized, aggregated analytics.
                        """)

                        sectionHeader("3. Data Security")
                        sectionBody("""
                        We take your data security seriously:

                        • Body photos are encrypted on device using iOS file protection.
                        • All data transmitted to our servers uses TLS 1.3 encryption.
                        • Photos stored in cloud storage use AES-256 server-side encryption.
                        • We do not sell, rent, or share your personal data or photos with third parties.
                        • AI analysis is performed through Anthropic's Claude API with enterprise-grade security.
                        """)
                    }

                    Group {
                        sectionHeader("4. Data Retention")
                        sectionBody("""
                        • Your data is retained for as long as your account is active.
                        • Upon account deletion, all personal data (including photos, scans, and profile information) is permanently deleted within 30 days.
                        • Anonymized, aggregated analytics data may be retained.
                        """)

                        sectionHeader("5. Your Rights")
                        sectionBody("""
                        You have the right to:

                        • Access: View all data we store about you (Profile > Export My Data).
                        • Deletion: Delete your account and all associated data at any time (Profile > Account > Delete Account).
                        • Portability: Export your data in a standard format.
                        • Opt-Out: Disable push notifications, analytics, or other optional features at any time.
                        """)

                        sectionHeader("6. Third-Party Services")
                        sectionBody("""
                        ASCEND uses the following third-party services:

                        • Apple In-App Purchase: For subscription payments.
                        • Anthropic Claude API: For AI-powered body analysis and IRIS message generation.
                        • Apple Push Notification Service (APNs): For push notifications.

                        Each service has its own privacy policy. We recommend reviewing them.
                        """)

                        sectionHeader("7. Children's Privacy")
                        sectionBody("ASCEND is rated 17+ and is not intended for use by anyone under 17 years of age. We do not knowingly collect data from individuals under 17.")

                        sectionHeader("8. Changes to This Policy")
                        sectionBody("We may update this Privacy Policy from time to time. We will notify you of significant changes through the App or via email.")

                        sectionHeader("9. Contact Us")
                        sectionBody("For privacy-related inquiries: privacy@ascendapp.us")
                    }

                    Text("Last updated: May 2025")
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary)
                        .padding(.top, 10)
                }
                .padding(20)
            }
            .background(Color.ds_navy)
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.ds_cyan)
                }
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(DSFont.sectionTitle)
            .foregroundStyle(Color.ds_textPrimary)
    }

    private func sectionBody(_ text: String) -> some View {
        Text(text)
            .font(DSFont.body)
            .foregroundStyle(Color.ds_textSecondary)
            .lineSpacing(4)
    }
}

// MARK: - Medical Disclaimer

struct MedicalDisclaimerView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.ds_cyan)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)

                    Text("Medical Disclaimer")
                        .font(DSFont.heroTitle)
                        .foregroundStyle(Color.ds_textPrimary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(alignment: .leading, spacing: 16) {
                        disclaimerItem(
                            "Not a Medical Device",
                            "ASCEND is a fitness tracking and motivational application. It is NOT a medical device and has not been evaluated, cleared, or approved by the FDA or any other regulatory body."
                        )

                        disclaimerItem(
                            "AI Feedback Limitations",
                            "AI-generated scores, body zone assessments, and IRIS coaching messages are based on visual analysis algorithms and are for general fitness guidance only. They should not be used to diagnose, treat, prevent, or cure any medical condition."
                        )

                        disclaimerItem(
                            "Consult a Professional",
                            "Always consult a qualified healthcare professional before beginning any fitness program, making dietary changes, or if you have concerns about your physical health. This is especially important if you have pre-existing medical conditions, injuries, or are pregnant."
                        )

                        disclaimerItem(
                            "Body Image Awareness",
                            "ASCEND uses objective measurements and AI analysis. Scores and feedback are not judgments of your worth. If you experience distress related to body image, please reach out to a mental health professional."
                        )

                        disclaimerItem(
                            "Accuracy",
                            "While we strive for accuracy, AI visual analysis has inherent limitations. Lighting, camera angle, clothing, and other factors may affect results. Scores are comparative trend indicators, not clinical measurements."
                        )

                        disclaimerItem(
                            "Liability",
                            "By using ASCEND, you acknowledge that the developers are not liable for any injuries, health complications, or other damages that may result from following AI-generated fitness guidance."
                        )
                    }

                    Text("If you are experiencing a medical emergency, call 911 or your local emergency number immediately.")
                        .font(DSFont.bodyBold)
                        .foregroundStyle(Color.ds_red)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
            .background(Color.ds_navy)
            .navigationTitle("Medical Disclaimer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.ds_cyan)
                }
            }
        }
    }

    private func disclaimerItem(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DSFont.sectionTitle)
                .foregroundStyle(Color.ds_textPrimary)
            Text(body)
                .font(DSFont.body)
                .foregroundStyle(Color.ds_textSecondary)
                .lineSpacing(4)
        }
        .padding(16)
        .background(Color.ds_charcoal)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
