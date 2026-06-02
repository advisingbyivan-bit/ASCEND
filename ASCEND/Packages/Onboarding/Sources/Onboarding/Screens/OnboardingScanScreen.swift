import SwiftUI
import DesignSystem
import Scanner

struct OnboardingScanScreen: View {
    let coordinator: OnboardingCoordinator

    var body: some View {
        ScanFlowView(onComplete: { photos in
            coordinator.scanPhotos = photos
            coordinator.advance()
        }, onDismiss: {
            // Skip scan — finish onboarding with empty state
            // User will see the home screen with no scan data
            coordinator.finishOnboarding()
        })
        .ignoresSafeArea()
    }
}
