import SwiftUI

public struct DSCard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(DSSpacing.md)
            .background(Color.ds_charcoal)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                    .stroke(Color.ds_cardBorder, lineWidth: 1)
            )
    }
}

public extension View {
    func dsCard() -> some View {
        self
            .padding(DSSpacing.md)
            .background(Color.ds_charcoal)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                    .stroke(Color.ds_cardBorder, lineWidth: 1)
            )
    }
}
