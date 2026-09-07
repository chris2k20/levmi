import SwiftUI

// MARK: - OwnSentenceBanner
//
// „Du hast geschrieben: …" beim nächsten Öffnen (poc-spec 1.3). Wischbar oder antippbar zum
// Schließen — kein Button, das Verschwinden selbst ist die Bestätigung (`dismissOwnSentence`).

struct OwnSentenceBanner: View {

    var sentence: String
    var date: Date
    var onDismiss: () -> Void

    @State private var offset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Du hast geschrieben:")
                .font(Theme.Font.eyebrow())
                .foregroundStyle(.secondary)
            Text("„\(sentence)\"")
                .font(Theme.Font.body().italic())
                .fixedSize(horizontal: false, vertical: true)
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(Theme.Font.footnote())
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: 520, alignment: .leading)
        .padding(Theme.Spacing.m)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardCornerRadius))
        .offset(x: offset)
        .opacity(1 - min(1, Double(abs(offset)) / 200))
        .gesture(
            DragGesture()
                .onChanged { value in offset = value.translation.width }
                .onEnded { value in
                    if abs(value.translation.width) > 80 {
                        dismissWithSwipe(direction: value.translation.width > 0 ? 1 : -1)
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { offset = 0 }
                    }
                }
        )
        .onTapGesture(perform: onDismiss)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Du hast geschrieben: \(sentence), \(date.formatted(date: .abbreviated, time: .omitted))")
        .accessibilityHint("Zum Schließen antippen")
        .accessibilityAction(named: "Schließen", onDismiss)
    }

    private func dismissWithSwipe(direction: CGFloat) {
        withAnimation(.easeOut(duration: reduceMotion ? 0.15 : 0.25)) {
            offset = direction * 500
        }
        Task {
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.15 : 0.25))
            onDismiss()
        }
    }
}
