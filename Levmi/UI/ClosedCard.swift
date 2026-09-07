import SwiftUI

// MARK: - ClosedCard
//
// „Für heute reicht's." — die App schickt den Spieler weg (poc-spec 1.2.5). Der Schalter meldet nur
// seinen neuen Wert nach außen; `AppModel.setReminderEnabled(_:)` holt die Erlaubnis ein, plant
// (oder storniert) die lokale Erinnerung und merkt sich die Präferenz. `initialRemindMe` kommt
// deshalb von `AppModel.reminderEnabled` (über Nächte hinweg in `UserDefaults` gemerkt), nicht aus
// einem eigenen Default dieser Karte.

struct ClosedCard: View {

    var initialRemindMe = false
    var onReminderToggled: (Bool) -> Void = { _ in }
    var onContinue: () -> Void

    @State private var remindMe: Bool

    init(
        initialRemindMe: Bool = false,
        onReminderToggled: @escaping (Bool) -> Void = { _ in },
        onContinue: @escaping () -> Void
    ) {
        self.initialRemindMe = initialRemindMe
        self.onReminderToggled = onReminderToggled
        self.onContinue = onContinue
        self._remindMe = State(initialValue: initialRemindMe)
    }

    var body: some View {
        LevmiCard(
            title: "Für heute reicht's.",
            bodyText: "Die Wurzeln arbeiten.\nKomm zurück, wenn du's getan hast.",
            primary: LevmiCardButton(title: "Weiter", action: onContinue)
        ) {
            Toggle(isOn: $remindMe) {
                Text("Erinnern, wenn die Tür aufgeht?")
                    .font(Theme.Font.footnote())
                    .foregroundStyle(.secondary)
            }
            .toggleStyle(.switch)
            .tint(Theme.Color.lightWarm)
            .onChange(of: remindMe) { _, newValue in onReminderToggled(newValue) }
            .accessibilityLabel("Erinnern, wenn die Tür aufgeht")
        }
    }
}
