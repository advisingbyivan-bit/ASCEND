import SwiftUI
import Diagnostics
import Networking

struct OnboardingDiagnosisScreen: View {
    let coordinator: OnboardingCoordinator

    /// Build user context from onboarding data so the first scan is personalized.
    private var userContext: ClaudeVisionClient.UserContext {
        let data = coordinator.data
        let concerns = data.bodyConcerns.map { $0.rawValue }.joined(separator: ", ")
        return ClaudeVisionClient.UserContext(
            heightCm: data.heightCm,
            weightKg: data.weightKg,
            goalWeightKg: data.goalWeight,
            age: data.age,
            gender: data.gender == .male ? "male" : "female",
            scanNumber: 1,
            currentStreak: 0,
            bodyConcerns: concerns,
            trainingFrequency: data.trainingFrequency.rawValue,
            timeline: data.timeline.rawValue,
            previousZones: nil
        )
    }

    var body: some View {
        DiagnosisRevealView(photos: coordinator.scanPhotos, userContext: userContext) { result in
            coordinator.diagnosisResult = result
            coordinator.advance()
        }
    }
}
