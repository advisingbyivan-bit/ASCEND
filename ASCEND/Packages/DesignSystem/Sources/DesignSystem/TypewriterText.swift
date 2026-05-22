import SwiftUI

public struct DSTypewriterText: View {
    let fullText: String
    let charDelay: Duration
    let onComplete: (() -> Void)?
    @State private var displayedText = ""
    @State private var currentIndex = 0

    public init(_ text: String, charDelay: Duration = .milliseconds(50), onComplete: (() -> Void)? = nil) {
        self.fullText = text
        self.charDelay = charDelay
        self.onComplete = onComplete
    }

    public var body: some View {
        Text(displayedText)
            .font(DSFont.body)
            .foregroundStyle(Color.ds_textPrimary)
            .task {
                for char in fullText {
                    displayedText.append(char)
                    try? await Task.sleep(for: charDelay)
                }
                onComplete?()
            }
    }
}
