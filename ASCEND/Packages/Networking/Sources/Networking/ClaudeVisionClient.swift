import Foundation

public final class ClaudeVisionClient: Sendable {
    public static let shared = ClaudeVisionClient()

    private let _apiKey: UnsafeMutablePointer<String>
    private let lock = NSLock()

    public var apiKey: String {
        get { lock.withLock { _apiKey.pointee } }
        set { lock.withLock { _apiKey.pointee = newValue } }
    }

    /// Base URL for the API proxy. When set, requests go through the proxy
    /// instead of directly to Anthropic. The proxy holds the API key server-side.
    private let _proxyBaseURL: UnsafeMutablePointer<String>

    public var proxyBaseURL: String {
        get { lock.withLock { _proxyBaseURL.pointee } }
        set { lock.withLock { _proxyBaseURL.pointee = newValue } }
    }

    private init() {
        _apiKey = .allocate(capacity: 1)
        _apiKey.initialize(to: "")
        _proxyBaseURL = .allocate(capacity: 1)
        _proxyBaseURL.initialize(to: "")
    }

    /// Context about the user that enriches the AI analysis.
    /// Passed alongside the photos so Claude can track progression.
    public struct UserContext: Sendable {
        public let heightCm: Int
        public let weightKg: Double
        public let goalWeightKg: Double
        public let age: Int
        public let gender: String
        public let scanNumber: Int
        public let currentStreak: Int
        /// Comma-separated body zones the user wants to focus on (e.g. "chest,arms,abs")
        public let bodyConcerns: String
        /// Training frequency description (e.g. "3-4x / week")
        public let trainingFrequency: String
        /// Goal timeline (e.g. "12 Weeks")
        public let timeline: String
        /// Previous scan's zone scores for delta comparison
        public let previousZones: [(zone: String, status: String, score: Double)]?

        public init(
            heightCm: Int = 0,
            weightKg: Double = 0,
            goalWeightKg: Double = 0,
            age: Int = 0,
            gender: String = "male",
            scanNumber: Int = 1,
            currentStreak: Int = 0,
            bodyConcerns: String = "",
            trainingFrequency: String = "",
            timeline: String = "",
            previousZones: [(zone: String, status: String, score: Double)]? = nil
        ) {
            self.heightCm = heightCm
            self.weightKg = weightKg
            self.goalWeightKg = goalWeightKg
            self.age = age
            self.gender = gender
            self.scanNumber = scanNumber
            self.currentStreak = currentStreak
            self.bodyConcerns = bodyConcerns
            self.trainingFrequency = trainingFrequency
            self.timeline = timeline
            self.previousZones = previousZones
        }
    }

    public func analyzeBody(
        frontImageData: Data,
        sideImageData: Data,
        backImageData: Data,
        context: UserContext = UserContext()
    ) async throws -> BodyAnalysisResponse {
        let key = apiKey
        let proxy = proxyBaseURL
        guard !key.isEmpty || !proxy.isEmpty else { throw ClaudeError.noAPIKey }

        // Use the proxy base URL if set, otherwise fall back to direct API
        let baseURL = proxyBaseURL.isEmpty ? "https://api.anthropic.com" : proxyBaseURL
        let url = URL(string: "\(baseURL)/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("us.ascend.app.app", forHTTPHeaderField: "X-App-Bundle")

        // Only send API key header when calling Anthropic directly (no proxy)
        if proxyBaseURL.isEmpty {
            request.setValue(key, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        }

        let frontBase64 = frontImageData.base64EncodedString()
        let sideBase64 = sideImageData.base64EncodedString()
        let backBase64 = backImageData.base64EncodedString()

        // Build context section for the prompt
        var contextLines: [String] = []
        if context.heightCm > 0 && context.weightKg > 0 {
            let bmi = context.weightKg / pow(Double(context.heightCm) / 100.0, 2)
            contextLines.append("Subject: \(context.gender), \(context.age)yo, \(context.heightCm)cm, \(context.weightKg)kg (BMI \(String(format: "%.1f", bmi)))")
            if context.goalWeightKg > 0 {
                contextLines.append("Goal weight: \(String(format: "%.1f", context.goalWeightKg))kg")
            }
        }
        if !context.bodyConcerns.isEmpty {
            contextLines.append("PRIORITY ZONES (user's focus areas): \(context.bodyConcerns). Pay extra attention to these zones — the user specifically wants to improve them. Call them out in the irisMessage.")
        }
        if !context.trainingFrequency.isEmpty {
            contextLines.append("Training frequency: \(context.trainingFrequency)")
        }
        if !context.timeline.isEmpty {
            contextLines.append("Goal timeline: \(context.timeline)")
        }
        contextLines.append("Scan #\(context.scanNumber). Streak: \(context.currentStreak) days.")
        if let prev = context.previousZones, !prev.isEmpty {
            let prevStr = prev.map { "\($0.zone): \($0.status)" }.joined(separator: ", ")
            contextLines.append("Previous scan zones: \(prevStr)")
            contextLines.append("DELTA should reflect change FROM previous scan (positive = improved, negative = declined). If this is a repeat scan within the same day, deltas should be near zero.")
        } else {
            contextLines.append("This is the user's first scan. DELTA should be 0 for all zones.")
        }
        let contextBlock = contextLines.joined(separator: "\n")

        let prompt = """
        You are IRIS, a brutally honest AI body diagnostician. Analyze these 3 body photos (front view, side view, back view) \
        and return ONLY valid JSON — no markdown, no explanation, no extra text.

        USER CONTEXT:
        \(contextBlock)

        JSON schema (follow EXACTLY):
        {"zones":[{"zone":"<zone>","status":"<status>","delta":<number>,"note":"<1 sentence>"}],"overallScore":<0-100>,"irisMessage":"<message>"}

        ZONES (use these exact names): shoulders, chest, arms, back, core, abs, glutes, legs
        STATUS values: "strong" (visibly developed, good definition), "moderate" (some development, room to grow), "weak" (underdeveloped, priority area)
        DELTA: % change since last scan (positive = improved, negative = declined, 0 = no change). Realistic range: -8 to +8 per week.

        Scoring guide:
        - 30-45: Beginner, minimal muscle development
        - 46-55: Some foundation, major gaps
        - 56-65: Intermediate, clear strengths and weaknesses
        - 66-75: Advanced, most zones developed
        - 76-85: Elite, near-complete development
        - 86+: Exceptional, competition-ready

        irisMessage rules:
        - 2-3 sentences max
        - Brutally honest, no sugar-coating
        - Call out the weakest zone by name
        - Acknowledge the strongest zone
        - If previous scan data exists, mention whether they improved or declined
        - End with a direct challenge or command
        - Sound like a coach who respects you but won't let you slack

        Evaluate muscle development, symmetry, posture, and body composition. Factor in the user's stats (height/weight/BMI) for body fat assessment. Be accurate — users trust you with the truth.
        """

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": frontBase64
                            ]
                        ],
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": sideBase64
                            ]
                        ],
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": backBase64
                            ]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ClaudeError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ClaudeError.apiError("Status \(httpResponse.statusCode): \(errorBody)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw ClaudeError.invalidResponse
        }

        let jsonText = extractJSON(from: text)

        guard let jsonData = jsonText.data(using: .utf8) else {
            throw ClaudeError.decodingError("Could not convert response text to data.")
        }

        do {
            return try JSONDecoder().decode(BodyAnalysisResponse.self, from: jsonData)
        } catch {
            throw ClaudeError.decodingError(error.localizedDescription)
        }
    }

    private func extractJSON(from text: String) -> String {
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }
        return text
    }
}
