import SwiftUI

// MARK: - IntentionCard
//
// Absicht wählen (poc-spec 1.2.4). Überschrift je nach Uhrzeit; drei feste Vorschläge aus der
// Karte „Der Schnitt" plus „Eigene…". Domain-Wrapping (`Intention.make`) macht `AppModel` —
// diese View liefert nur den gewählten/eingegebenen Text.

struct IntentionCard: View {

    static let suggestions = [
        "Sag zu einer lauwarmen Sache ab. Ein Satz.",
        "Streich ein Vorhaben, das seit Wochen hängt.",
        "Schreib fünf offene Dinge auf, markiere GRAU.",
    ]

    /// Für die Überschrift: vor 20 Uhr „Klein genug für heute.", danach „…für morgen früh."
    var now: Date = Date()
    var onChoose: (String) -> Void

    @State private var showsCustomField = false
    @State private var customText = ""
    @FocusState private var isFocused: Bool

    private var title: String {
        Calendar.current.component(.hour, from: now) >= 20
            ? "Klein genug für morgen früh."
            : "Klein genug für heute."
    }

    var body: some View {
        LevmiCard(title: title) {
            VStack(spacing: Theme.Spacing.s) {
                ForEach(Self.suggestions, id: \.self) { suggestion in
                    Button {
                        onChoose(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(Theme.Font.body())
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget, alignment: .leading)
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel(suggestion)
                }

                if showsCustomField {
                    HStack(spacing: Theme.Spacing.s) {
                        TextField("Eigene Absicht", text: $customText, axis: .vertical)
                            .focused($isFocused)
                            .font(Theme.Font.body())
                            .padding(Theme.Spacing.s)
                            .background(RoundedRectangle(cornerRadius: 14).fill(SwiftUI.Color.white.opacity(0.08)))
                            .accessibilityLabel("Eigene Absicht")

                        Button("Weiter") { onChoose(customText) }
                            .buttonStyle(.glassProminent)
                            .disabled(customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .frame(minHeight: Theme.minTapTarget)
                    }
                    .onAppear { isFocused = true }
                } else {
                    Button {
                        withAnimation { showsCustomField = true }
                    } label: {
                        Text("Eigene…")
                            .font(Theme.Font.body())
                            .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel("Eigene Absicht eingeben")
                }
            }
        }
    }
}
