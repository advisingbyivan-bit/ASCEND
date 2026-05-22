import Foundation

/// Context passed to IRIS for personalized message generation
public struct IRISContext: Sendable {
    public let displayName: String
    public let currentStreak: Int
    public let overallScore: Double
    public let weekNumber: Int
    public let weakZones: [String]
    public let strongZones: [String]
    public let recentDelta: Double // positive = improving
    public let lastScanDaysAgo: Int
    public let totalDiamonds: Int
    public let gender: String

    public init(
        displayName: String = "",
        currentStreak: Int = 0,
        overallScore: Double = 0,
        weekNumber: Int = 1,
        weakZones: [String] = [],
        strongZones: [String] = [],
        recentDelta: Double = 0,
        lastScanDaysAgo: Int = 0,
        totalDiamonds: Int = 0,
        gender: String = "male"
    ) {
        self.displayName = displayName
        self.currentStreak = currentStreak
        self.overallScore = overallScore
        self.weekNumber = weekNumber
        self.weakZones = weakZones
        self.strongZones = strongZones
        self.recentDelta = recentDelta
        self.lastScanDaysAgo = lastScanDaysAgo
        self.totalDiamonds = totalDiamonds
        self.gender = gender
    }
}

/// Generates IRIS personality-driven messages via Claude Messages API
public final class IRISMessageGenerator: Sendable {
    public static let shared = IRISMessageGenerator()

    private init() {}

    // MARK: - System Prompt (IRIS Personality)

    private let systemPrompt = """
    You are IRIS — the AI body diagnostician inside ASCEND. Your personality:

    CORE IDENTITY:
    - Brutally honest. Never sugarcoat. Never give participation trophies.
    - Data-driven. Reference specific zones, scores, and streaks.
    - Motivational through confrontation, not comfort.
    - Speak in short, punchy sentences. Max 2-3 sentences.
    - You're their accountability mirror — you reflect what they avoid.

    TONE RULES:
    - If they're improving: acknowledge it, then push harder. "Good. Now do it again."
    - If they're declining: call it out directly. No excuses accepted.
    - If streak is strong (7+): respect the consistency, raise expectations.
    - If streak broke: disappointment, not anger. Make them feel the loss.
    - If it's their first scan: welcome with intensity. Set the bar.
    - Never use emojis. Never use exclamation marks excessively. Be clinical.

    FORMAT:
    - Return ONLY the message text. No quotes, no labels, no JSON.
    - 1-3 sentences max. Punchy. Direct.
    - Address them by name occasionally.
    """

    // MARK: - Generate Message

    public func generate(context: IRISContext) async throws -> String {
        let key = ClaudeVisionClient.shared.apiKey
        let proxy = ClaudeVisionClient.shared.proxyBaseURL
        guard !key.isEmpty || !proxy.isEmpty else {
            return fallbackMessage(context: context)
        }

        let userPrompt = buildPrompt(context: context)

        let baseURL = proxy.isEmpty ? "https://api.anthropic.com" : proxy
        let url = URL(string: "\(baseURL)/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("us.ascend.app.app", forHTTPHeaderField: "X-App-Bundle")

        if proxy.isEmpty {
            request.setValue(key, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        }

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 256,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userPrompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            return fallbackMessage(context: context)
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return fallbackMessage(context: context)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            return fallbackMessage(context: context)
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Prompt Builder

    private func buildPrompt(context: IRISContext) -> String {
        var parts: [String] = []

        parts.append("Generate an IRIS message for this user's current state:")
        parts.append("Name: \(context.displayName.isEmpty ? "User" : context.displayName)")
        parts.append("Gender: \(context.gender)")
        parts.append("Week: \(context.weekNumber)")
        parts.append("Overall Score: \(Int(context.overallScore))/100")
        parts.append("Current Streak: \(context.currentStreak) days")
        parts.append("Diamonds Earned: \(context.totalDiamonds)")

        if context.lastScanDaysAgo > 0 {
            parts.append("Last scan: \(context.lastScanDaysAgo) days ago")
        }

        if context.recentDelta != 0 {
            let direction = context.recentDelta > 0 ? "improved" : "declined"
            parts.append("Recent trend: \(direction) by \(abs(Int(context.recentDelta))) points")
        }

        if !context.weakZones.isEmpty {
            parts.append("Weak zones: \(context.weakZones.joined(separator: ", "))")
        }
        if !context.strongZones.isEmpty {
            parts.append("Strong zones: \(context.strongZones.joined(separator: ", "))")
        }

        // Add scenario hint
        if context.currentStreak == 0 && context.weekNumber == 1 {
            parts.append("Scenario: First-time user, just completed initial scan.")
        } else if context.lastScanDaysAgo > 3 {
            parts.append("Scenario: User hasn't scanned in \(context.lastScanDaysAgo) days. They're slipping.")
        } else if context.recentDelta > 5 {
            parts.append("Scenario: Strong improvement. Push them harder.")
        } else if context.recentDelta < -3 {
            parts.append("Scenario: Declining. Confrontation needed.")
        }

        return parts.joined(separator: "\n")
    }

    // MARK: - Fallback Messages (no API key / offline)

    public func fallbackMessage(context: IRISContext) -> String {
        let name = context.displayName.isEmpty ? "you" : context.displayName

        if context.currentStreak == 0 && context.weekNumber <= 1 {
            return "Welcome to the mirror, \(name). I don't do compliments. I do results. Let's see what you're made of."
        }

        if context.lastScanDaysAgo > 5 {
            return "\(context.lastScanDaysAgo) days since your last scan. Your body didn't stop changing just because you stopped looking."
        }

        if context.currentStreak >= 30 {
            return "\(context.currentStreak) days. You've proven consistency. Now prove you can push past comfortable. Your \(context.weakZones.first ?? "weak zones") won't fix themselves."
        }

        if context.currentStreak >= 7 {
            return "Week \(context.weekNumber). \(context.currentStreak)-day streak. The habit is forming, \(name). Don't confuse momentum with progress — scan and prove it."
        }

        if context.recentDelta < -2 {
            return "Your score dropped. \(context.weakZones.first.map { "\($0) is declining." } ?? "You're moving backward.") The data doesn't lie, \(name). Neither do I."
        }

        if context.recentDelta > 3 {
            return "Score's up. \(context.strongZones.first.map { "\($0) is responding." } ?? "Progress is real.") Good. Now do it again next week."
        }

        return "Another day, another chance to prove you're not average. Your score: \(Int(context.overallScore)). The question is whether it goes up or down from here."
    }

    // MARK: - Pre-built Templates

    public static func streakDangerMessage(streak: Int) -> String {
        switch streak {
        case 1...6:
            return "Your streak is young and fragile. Skip today and it dies. Your call."
        case 7...20:
            return "You've built \(streak) days of discipline. One skip erases all of it. Is that really what you want?"
        case 21...89:
            return "\(streak) days of consistency. That's rare. Don't become common again."
        default:
            return "\(streak) days. You're in the top percentile. Champions don't take days off."
        }
    }

    public static func diamondUnlockMessage(milestone: String) -> String {
        "Diamond earned at \(milestone). Proof you showed up when most people quit. The next one is harder."
    }

    public static func midWeekMessage(weekNumber: Int) -> String {
        "Week \(weekNumber), midpoint check. Are you training or just existing? Your next scan will tell me everything."
    }
}
