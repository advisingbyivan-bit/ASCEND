import SwiftUI
import DesignSystem
import Scanner

struct OnboardingScanScreen: View {
    let coordinator: OnboardingCoordinator

    var body: some View {
        ScanFlowView { photos in
            coordinator.scanPhotos = photos
            coordinator.advance()
        }
        .ignoresSafeArea()
    }
}
