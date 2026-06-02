import SwiftUI

public struct DSCard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(DSSpacing.md)
            .dsGlass()
    }
}

public extension View {
    func dsCard() -> some View {
        self
            .padding(DSSpacing.md)
            .dsGlass()
    }
}
