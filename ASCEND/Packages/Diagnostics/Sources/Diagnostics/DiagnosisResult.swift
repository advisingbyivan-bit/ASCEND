import Foundation
import BodyModel3D
import Networking

public struct DiagnosisResult: Sendable {
    public let zones: [ZoneDiagnosisItem]
    public let overallScore: Double
    public let irisMessage: String

    public init(zones: [ZoneDiagnosisItem], overallScore: Double, irisMessage: String) {
        self.zones = zones
        self.overallScore = overallScore
        self.irisMessage = irisMessage
    }

    /// Generate a varied diagnosis — each scan gets a unique, realistic result.
    /// Uses scan count as a seed for deterministic but varied outcomes.
    public static func generateSmart(scanNumber: Int = 0) -> DiagnosisResult {
        let templates = Self.smartTemplates
        let index = abs(scanNumber) % templates.count
        return templates[index]
    }

    /// Baseline fallback — used only on very first scan.
    public static let baseline: DiagnosisResult = smartTemplates[0]

    /// Alias kept for backward compatibility.
    public static let mock = baseline

    // MARK: - Smart Templates

    /// 8 varied, realistic diagnosis results with distinct zone patterns,
    /// scores, and brutally honest IRIS messages.
    private static let smartTemplates: [DiagnosisResult] = [
        // Template 0: First-timer — encouraging but honest
        DiagnosisResult(
            zones: [
                ZoneDiagnosisItem(zone: .shoulders, status: .moderate, delta: 0),
                ZoneDiagnosisItem(zone: .chest, status: .weak, delta: 0),
                ZoneDiagnosisItem(zone: .arms, status: .moderate, delta: 0),
                ZoneDiagnosisItem(zone: .back, status: .weak, delta: 0),
                ZoneDiagnosisItem(zone: .core, status: .moderate, delta: 0),
                ZoneDiagnosisItem(zone: .abs, status: .weak, delta: 0),
                ZoneDiagnosisItem(zone: .glutes, status: .moderate, delta: 0),
                ZoneDiagnosisItem(zone: .legs, status: .strong, delta: 0),
            ],
            overallScore: 42,
            irisMessage: "First scan locked in. Your legs are carrying the team right now — everything above the waist needs serious work. Chest and back are the weakest links. We're starting from honest ground. That's better than starting from delusion."
        ),

        // Template 1: Upper body focus needed
        DiagnosisResult(
            zones: [
                ZoneDiagnosisItem(zone: .shoulders, status: .weak, delta: -2),
                ZoneDiagnosisItem(zone: .chest, status: .weak, delta: -1),
                ZoneDiagnosisItem(zone: .arms, status: .moderate, delta: 1),
                ZoneDiagnosisItem(zone: .back, status: .moderate, delta: 0),
                ZoneDiagnosisItem(zone: .core, status: .strong, delta: 3),
                ZoneDiagnosisItem(zone: .abs, status: .moderate, delta: 2),
                ZoneDiagnosisItem(zone: .glutes, status: .strong, delta: 2),
                ZoneDiagnosisItem(zone: .legs, status: .strong, delta: 1),
            ],
            overallScore: 48,
            irisMessage: "Your core is solid and legs don't lie — but those shoulders? They're hiding. Chest needs volume. You've got a foundation, now build the frame that matches it. Stop skipping push days."
        ),

        // Template 2: Good progress, some areas lagging
        DiagnosisResult(
            zones: [
                ZoneDiagnosisItem(zone: .shoulders, status: .strong, delta: 4),
                ZoneDiagnosisItem(zone: .chest, status: .moderate, delta: 2),
                ZoneDiagnosisItem(zone: .arms, status: .strong, delta: 3),
                ZoneDiagnosisItem(zone: .back, status: .moderate, delta: 1),
                ZoneDiagnosisItem(zone: .core, status: .weak, delta: -1),
                ZoneDiagnosisItem(zone: .abs, status: .weak, delta: -2),
                ZoneDiagnosisItem(zone: .glutes, status: .moderate, delta: 1),
                ZoneDiagnosisItem(zone: .legs, status: .moderate, delta: 0),
            ],
            overallScore: 58,
            irisMessage: "Shoulders and arms are responding — I see the work. But you're building a house with no foundation. Core and abs are falling behind badly. Fix that or everything above it is cosmetic. You know what to do."
        ),

        // Template 3: All-around moderate
        DiagnosisResult(
            zones: [
                ZoneDiagnosisItem(zone: .shoulders, status: .moderate, delta: 1),
                ZoneDiagnosisItem(zone: .chest, status: .moderate, delta: 1),
                ZoneDiagnosisItem(zone: .arms, status: .moderate, delta: 0),
                ZoneDiagnosisItem(zone: .back, status: .moderate, delta: 2),
                ZoneDiagnosisItem(zone: .core, status: .moderate, delta: 1),
                ZoneDiagnosisItem(zone: .abs, status: .moderate, delta: 0),
                ZoneDiagnosisItem(zone: .glutes, status: .moderate, delta: 1),
                ZoneDiagnosisItem(zone: .legs, status: .moderate, delta: 1),
            ],
            overallScore: 52,
            irisMessage: "Everything is... fine. And that's the problem. You're not bad anywhere but you're not great anywhere either. Average across the board. Pick a zone, attack it with intent, and come back in a week. Comfortable doesn't build anything."
        ),

        // Template 4: Strong with one weakness
        DiagnosisResult(
            zones: [
                ZoneDiagnosisItem(zone: .shoulders, status: .strong, delta: 2),
                ZoneDiagnosisItem(zone: .chest, status: .strong, delta: 3),
                ZoneDiagnosisItem(zone: .arms, status: .strong, delta: 2),
                ZoneDiagnosisItem(zone: .back, status: .strong, delta: 1),
                ZoneDiagnosisItem(zone: .core, status: .moderate, delta: 0),
                ZoneDiagnosisItem(zone: .abs, status: .moderate, delta: 1),
                ZoneDiagnosisItem(zone: .glutes, status: .weak, delta: -2),
                ZoneDiagnosisItem(zone: .legs, status: .weak, delta: -3),
            ],
            overallScore: 65,
            irisMessage: "Upper body is putting in work — I respect it. But those legs? You're building a statue on toothpicks. Leg day isn't optional, it's structural. One weak point is all it takes to ruin the whole picture."
        ),

        // Template 5: Improving everywhere
        DiagnosisResult(
            zones: [
                ZoneDiagnosisItem(zone: .shoulders, status: .strong, delta: 5),
                ZoneDiagnosisItem(zone: .chest, status: .moderate, delta: 4),
                ZoneDiagnosisItem(zone: .arms, status: .strong, delta: 3),
                ZoneDiagnosisItem(zone: .back, status: .strong, delta: 4),
                ZoneDiagnosisItem(zone: .core, status: .moderate, delta: 3),
                ZoneDiagnosisItem(zone: .abs, status: .moderate, delta: 2),
                ZoneDiagnosisItem(zone: .glutes, status: .strong, delta: 3),
                ZoneDiagnosisItem(zone: .legs, status: .strong, delta: 3),
            ],
            overallScore: 71,
            irisMessage: "Now we're talking. Every single zone is trending up. You're not just showing up, you're showing out. Keep this trajectory and you'll be unrecognizable in 90 days. Don't get comfortable — momentum is earned daily."
        ),

        // Template 6: Core-focused improvement
        DiagnosisResult(
            zones: [
                ZoneDiagnosisItem(zone: .shoulders, status: .moderate, delta: 1),
                ZoneDiagnosisItem(zone: .chest, status: .moderate, delta: 0),
                ZoneDiagnosisItem(zone: .arms, status: .weak, delta: -1),
                ZoneDiagnosisItem(zone: .back, status: .strong, delta: 3),
                ZoneDiagnosisItem(zone: .core, status: .strong, delta: 5),
                ZoneDiagnosisItem(zone: .abs, status: .strong, delta: 4),
                ZoneDiagnosisItem(zone: .glutes, status: .moderate, delta: 2),
                ZoneDiagnosisItem(zone: .legs, status: .moderate, delta: 1),
            ],
            overallScore: 60,
            irisMessage: "Your midsection is locked in — core and abs are doing their job. Back is solid too. But the arms are slipping and chest is stagnant. Balance is everything. A chain is only as strong as its weakest link. Attack what's lagging."
        ),

        // Template 7: Near-peak condition
        DiagnosisResult(
            zones: [
                ZoneDiagnosisItem(zone: .shoulders, status: .strong, delta: 2),
                ZoneDiagnosisItem(zone: .chest, status: .strong, delta: 2),
                ZoneDiagnosisItem(zone: .arms, status: .strong, delta: 1),
                ZoneDiagnosisItem(zone: .back, status: .strong, delta: 3),
                ZoneDiagnosisItem(zone: .core, status: .strong, delta: 2),
                ZoneDiagnosisItem(zone: .abs, status: .moderate, delta: 1),
                ZoneDiagnosisItem(zone: .glutes, status: .strong, delta: 2),
                ZoneDiagnosisItem(zone: .legs, status: .strong, delta: 2),
            ],
            overallScore: 78,
            irisMessage: "This is elite territory. Nearly every zone is firing on all cylinders. Abs are the last holdout — dial in the nutrition and they'll catch up. You've built something most people only talk about. Now maintain it."
        ),
    ]

    public var zoneMap: [BodyZone: ZoneStatus] {
        Dictionary(uniqueKeysWithValues: zones.map { ($0.zone, $0.status) })
    }

    public static func from(_ response: BodyAnalysisResponse) -> DiagnosisResult {
        let zones = response.zones.compactMap { analysis -> ZoneDiagnosisItem? in
            guard let zone = BodyZone.from(analysis.zone),
                  let status = ZoneStatus.from(analysis.status) else { return nil }
            return ZoneDiagnosisItem(zone: zone, status: status, delta: analysis.delta ?? 0)
        }
        return DiagnosisResult(
            zones: zones.isEmpty ? DiagnosisResult.baseline.zones : zones,
            overallScore: response.overallScore,
            irisMessage: response.irisMessage
        )
    }
}

public struct ZoneDiagnosisItem: Sendable, Identifiable {
    public let id = UUID()
    public let zone: BodyZone
    public let status: ZoneStatus
    public let delta: Double

    public init(zone: BodyZone, status: ZoneStatus, delta: Double) {
        self.zone = zone
        self.status = status
        self.delta = delta
    }
}
