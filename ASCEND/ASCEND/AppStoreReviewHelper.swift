import Foundation

// MARK: - App Store Review Configuration
// This file contains all metadata and configurations needed for App Store submission.

enum AppStoreConfig {

    // MARK: - App Metadata

    static let appName = "ASCEND"
    static let subtitle = "AI Body Diagnostician"
    static let bundleID = "us.ascendapp.app"
    static let category = "Health & Fitness"
    static let secondaryCategory = "Lifestyle"
    static let ageRating = "17+"
    static let version = "1.0.0"
    static let buildNumber = "1"

    // MARK: - URLs (must be live before submission)

    static let supportURL = "https://ascendapp.us/support"
    static let marketingURL = "https://ascendapp.us"
    static let privacyPolicyURL = "https://ascendapp.us/privacy"
    static let termsOfUseURL = "https://ascendapp.us/terms"

    // MARK: - App Store Description

    static let description = """
    ASCEND is your AI-powered body diagnostician and accountability mirror.

    FACE ID-STYLE BODY SCAN
    Stand in front of your camera. ASCEND captures front, side, and back views using advanced body pose detection. No manual measurements. No guessing.

    IRIS — YOUR AI ACCOUNTABILITY COACH
    Meet IRIS, a brutally honest AI that doesn't sugarcoat your progress. IRIS analyzes your body composition, identifies weak zones, and delivers raw, data-driven coaching. No participation trophies.

    HOLOGRAPHIC 3D BODY TWIN
    See your body as a color-coded holographic model. Red zones need work. Green zones are strong. Watch your zones change color as you progress week over week.

    TRACK EVERYTHING
    • Weekly body scans with AI-powered diagnostics
    • Zone-by-zone breakdown (shoulders, chest, arms, core, back, legs)
    • Before/after 3D model comparisons
    • 12-week consistency tracking
    • Streak tracking with diamond milestones

    COMPETE & CONNECT
    Join the global leaderboard. Compare progress with friends. Earn badges and diamonds for consistency.

    PREMIUM FEATURES
    • Unlimited body scans
    • Full IRIS coaching with personalized insights
    • Advanced progress analytics
    • Priority AI processing

    3-day free trial, then $29.99/year or $9.99/month. Cancel anytime.

    ASCEND is not a medical device. AI feedback is for fitness guidance only. Consult a healthcare professional for medical advice.
    """

    // MARK: - Keywords (max 100 characters)

    static let keywords = "body,scan,fitness,AI,coach,transformation,tracker,workout,progress,muscle"

    // MARK: - What's New (for updates)

    static let whatsNew = """
    Welcome to ASCEND 1.0 — the AI body diagnostician that doesn't lie.

    • Face ID-style body scanning
    • IRIS AI coaching with brutal honesty
    • Holographic 3D body twin
    • Zone-by-zone diagnostics
    • Streak tracking & diamond milestones
    • Global leaderboard
    """

    // MARK: - Demo Account for Apple Reviewers

    // Reviewer credentials belong in App Store Connect submission notes, not in source code.
    // static let reviewerEmail = ""
    // static let reviewerPassword = ""
    static let reviewerNotes = """
    Demo account is pre-loaded with sample data including:
    - 4 weeks of scan history
    - 7-day streak with diamond earned
    - Multiple body zones with progress data
    - Leaderboard ranking

    To test the full scan flow:
    1. Tap the Scan tab (camera icon)
    2. Camera permission is required for body scanning
    3. Follow the on-screen prompts for front/side/back photos

    Note: AI diagnostics require an active internet connection for Claude Vision API processing.

    Subscription testing:
    - Use sandbox Apple ID for in-app purchase testing
    - 3-day trial → yearly ($29.99) or monthly ($9.99)
    """

    // MARK: - Privacy Nutrition Labels

    enum DataCollected: String, CaseIterable {
        case bodyPhotos = "Photos or Videos — Linked to You — App Functionality"
        case emailAddress = "Email Address — Linked to You — App Functionality"
        case userID = "User ID — Linked to You — App Functionality"
        case name = "Name — Linked to You — App Functionality"
        case healthFitness = "Health & Fitness — Linked to You — App Functionality"
        case purchaseHistory = "Purchase History — Linked to You — App Functionality"
        case productInteraction = "Product Interaction — Not Linked to You — Analytics"
    }

    // MARK: - Screenshot Descriptions (6 required)

    static let screenshotDescriptions = [
        "1. Dashboard — Focus area with 3D body model, stats row, streak tracker, IRIS message card",
        "2. Body Scan — Face ID-style scanning interface with body pose frame overlay",
        "3. Diagnosis Reveal — IRIS sphere processing with sequential zone lighting on 3D model",
        "4. Progress — 12-week timeline with zone-by-zone breakdown and consistency grid",
        "5. Community — Global leaderboard with top 3 podium, badges, and streaks",
        "6. IRIS Coaching — Holographic sphere with brutally honest typewriter message",
    ]
}

// MARK: - Seed Data Generator (for demo/review accounts)

enum SeedDataGenerator {

    struct SeedScan {
        let weekNumber: Int
        let overallScore: Double
        let irisMessage: String
        let zones: [(name: String, status: String, delta: Double?)]
    }

    static let sampleScans: [SeedScan] = [
        SeedScan(
            weekNumber: 1,
            overallScore: 52,
            irisMessage: "First scan logged. Your shoulders are your weakest link — I can see the asymmetry from here. Core is decent. Let's see if you actually show up next week.",
            zones: [
                ("Shoulders", "declining", -2.0),
                ("Chest", "maintaining", nil),
                ("Arms", "maintaining", nil),
                ("Core", "improving", 1.5),
                ("Back", "declining", -1.0),
                ("Legs", "maintaining", nil),
            ]
        ),
        SeedScan(
            weekNumber: 2,
            overallScore: 55,
            irisMessage: "Score up 3 points. Core is responding. But your shoulders haven't moved — are you actually training them or just showing up?",
            zones: [
                ("Shoulders", "maintaining", 0.5),
                ("Chest", "improving", 2.0),
                ("Arms", "improving", 1.0),
                ("Core", "improving", 3.0),
                ("Back", "maintaining", 0.5),
                ("Legs", "improving", 1.5),
            ]
        ),
        SeedScan(
            weekNumber: 3,
            overallScore: 59,
            irisMessage: "Three weeks in. Most people have quit by now. Your back is finally waking up. Shoulders still lagging. Fix it or accept mediocrity.",
            zones: [
                ("Shoulders", "improving", 1.0),
                ("Chest", "improving", 1.5),
                ("Arms", "improving", 2.0),
                ("Core", "improving", 2.5),
                ("Back", "improving", 3.0),
                ("Legs", "maintaining", 0.5),
            ]
        ),
        SeedScan(
            weekNumber: 4,
            overallScore: 64,
            irisMessage: "Four weeks. Score jumped 5 points. Every zone is moving in the right direction. This is where discipline becomes identity. Don't stop now.",
            zones: [
                ("Shoulders", "improving", 2.5),
                ("Chest", "improving", 2.0),
                ("Arms", "improving", 1.5),
                ("Core", "improving", 3.0),
                ("Back", "improving", 2.0),
                ("Legs", "improving", 2.5),
            ]
        ),
    ]

    static let sampleLeaderboardEntries: [(name: String, focus: String, score: Double, progress: Double, streak: Int, diamonds: Int, badge: String)] = [
        ("Marcus_W", "Chest", 87, 78, 42, 3, "IRIS Veteran"),
        ("SophiaFit", "Core", 84, 85, 35, 2, "IRIS Trusted"),
        ("JakeLifts", "Shoulders", 81, 72, 28, 2, "IRIS Trusted"),
        ("ArianO", "Back", 79, 68, 21, 1, "7-Day Streak"),
        ("DevPatel", "Arms", 76, 65, 18, 1, "7-Day Streak"),
        ("You", "Core", 64, 52, 7, 1, "7-Day Streak"),
        ("EmmaStone", "Legs", 62, 48, 14, 1, "7-Day Streak"),
        ("AlexRun", "Core", 58, 42, 9, 1, "First Scan"),
        ("MayaK", "Shoulders", 55, 38, 5, 0, "First Scan"),
        ("ChrisP", "Back", 51, 35, 3, 0, "First Scan"),
    ]
}
