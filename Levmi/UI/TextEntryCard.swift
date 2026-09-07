import SwiftUI

// MARK: - TextEntryCard
//
// EINE Komponente, mehrere Konfigurationen: „Wenn das wahr wäre — was wäre anders?" (1.2.3, Skip
// erlaubt), der Beweis „Hast du es getan?" (1.3, mehrzeilig, ≥ 40 Zeichen, kein Skip, kein
// Zeichenzähler — Rückmeldung ist extern über `onReady`), die Kosten-Frage „Was war unangenehm
// daran?" (1.3, Skip erlaubt). `GameView` konfiguriert je Phase.

struct TextEntryCard: View {

    var eyebrow: String?
    var title: String
    var placeholder: String
    var isMultiline = false
    /// `nil` = keine Mindestlänge (Wofür?/Kosten-Frage). Gesetzt = Beweisfeld (40 Zeichen).
    var minCharsForReady: Int?
    var submitLabel = "Weiter"
    var skipAllowed = true
    var footnote: String? = "Bleibt auf deinem Gerät."
    /// Extern gesetzt, nachdem `GameEngine` den Text abgelehnt hat (`.reject(reason:)`).
    var rejectionMessage: String?
    /// Wird bei jeder Änderung mit „ist bereit?" aufgerufen (Beweisfeld: Sonne beginnt zu glimmen).
    var onReady: ((Bool) -> Void)?
    var onSubmit: (String) -> Void
    var onSkip: (() -> Void)?

    @State private var text = ""
    @FocusState private var isFocused: Bool

    private var isReady: Bool {
        guard let minCharsForReady else { return true }
        return text.trimmingCharacters(in: .whitespacesAndNewlines).count >= minCharsForReady
    }

    var body: some View {
        LevmiCard(
            eyebrow: eyebrow,
            title: title,
            footnote: footnote,
            primary: LevmiCardButton(title: submitLabel, isEnabled: isReady, action: { onSubmit(text) }),
            secondary: skipAllowed ? LevmiCardButton(title: "Überspringen", action: { onSkip?() }) : nil
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Group {
                    if isMultiline {
                        TextEditor(text: $text)
                            .frame(minHeight: 96, maxHeight: 150)
                            .scrollContentBackground(.hidden)
                    } else {
                        TextField(placeholder, text: $text, axis: .vertical)
                    }
                }
                .focused($isFocused)
                .font(Theme.Font.body())
                .padding(Theme.Spacing.s)
                .background(RoundedRectangle(cornerRadius: 14).fill(SwiftUI.Color.white.opacity(0.08)))
                .overlay(alignment: .topLeading) {
                    if isMultiline && text.isEmpty {
                        Text(placeholder)
                            .font(Theme.Font.body())
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(.horizontal, Theme.Spacing.s + 4)
                            .padding(.vertical, Theme.Spacing.s + 8)
                            .allowsHitTesting(false)
                    }
                }
                .accessibilityLabel(title)
                .accessibilityHint(placeholder)

                if let rejectionMessage {
                    Text(rejectionMessage)
                        .font(Theme.Font.footnote())
                        .foregroundStyle(Theme.Color.lightWarm)
                        .accessibilityLabel(rejectionMessage)
                }
            }
        }
        .onChange(of: text) { _, newValue in
            guard minCharsForReady != nil else { return }
            let ready = newValue.trimmingCharacters(in: .whitespacesAndNewlines).count >= minCharsForReady!
            onReady?(ready)
        }
    }
}
