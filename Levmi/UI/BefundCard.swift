import SwiftUI

// MARK: - BefundCard
//
// Der Satz über den Spieler — intern „Befund", das Wort erscheint nie in der UI (poc-spec 1.3,
// Textblatt §5). Nur der Satz, groß, plus „Stimmt" / „Stimmt nicht". Zeigt `sentence` unverändert
// an; ob es der erste Satz oder die Alternative ist, entscheidet `AppModel`/`GameEngine`.

struct BefundCard: View {

    var sentence: String
    var onAnswer: (_ accepted: Bool) -> Void

    var body: some View {
        LevmiCard(
            title: sentence,
            primary: LevmiCardButton(title: "Stimmt", action: { onAnswer(true) }),
            secondary: LevmiCardButton(title: "Stimmt nicht", action: { onAnswer(false) })
        )
    }
}
