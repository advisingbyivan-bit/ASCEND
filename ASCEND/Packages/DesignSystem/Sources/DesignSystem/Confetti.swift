import SwiftUI

public struct DSConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var isActive = false
    let colors: [Color] = [.ds_cyan, .ds_purple, .ds_green, .ds_yellow, .ds_gold]

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(confettiPieces) { piece in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(piece.color)
                        .frame(width: piece.width, height: piece.height)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(piece.position)
                        .opacity(piece.opacity)
                }
            }
            .onAppear {
                burst(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    public func burst(in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.3)
        confettiPieces = (0..<30).map { _ in
            ConfettiPiece(
                color: colors.randomElement()!,
                width: CGFloat.random(in: 4...8),
                height: CGFloat.random(in: 8...16),
                position: center,
                rotation: Double.random(in: 0...360),
                opacity: 1
            )
        }

        for i in confettiPieces.indices {
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 80...200)
            let dest = CGPoint(
                x: center.x + cos(angle) * distance,
                y: center.y + sin(angle) * distance + CGFloat.random(in: 100...300)
            )

            withAnimation(.easeOut(duration: Double.random(in: 1.0...1.8)).delay(Double.random(in: 0...0.2))) {
                confettiPieces[i].position = dest
                confettiPieces[i].rotation = Double.random(in: 0...720)
            }
            withAnimation(.easeIn(duration: 0.5).delay(1.2)) {
                confettiPieces[i].opacity = 0
            }
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let width: CGFloat
    let height: CGFloat
    var position: CGPoint
    var rotation: Double
    var opacity: Double
}
