import SwiftUI

// MARK: - HintLine
//
// Kleiner Affordance-Text unten (nach Zögern, poc-spec 1.1) oder eine einmalige Konsequenz-Zeile
// (Text 1 „Du hast ein Licht.", Text 2 „Das Lauwarme hat dein Licht gefressen."). Reine Anzeige —
// WANN sie erscheint, entscheidet die Phase-/Timer-Logik der aufrufenden View (`GameView`).

struct HintLine: View {

    let text: String
    var isVisible: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(text)
            .font(Theme.Font.footnote().weight(.medium))
            .foregroundStyle(.white.opacity(0.92))
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
            .glassEffect(.regular, in: .capsule)
            .opacity(isVisible ? 1 : 0)
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: reduceMotion ? 0.25 : 0.5), value: isVisible)
            .accessibilityLabel(text)
            .accessibilityHidden(!isVisible)
    }
}
