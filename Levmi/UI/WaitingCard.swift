import SwiftUI

// MARK: - WaitingCard
//
// Rückkehr vor `readyAt` (poc-spec 1.3): kein Beweis möglich, nur die Uhrzeit — kein rückwärts
// laufender Timer.

struct WaitingCard: View {

    var readyAt: Date

    var body: some View {
        LevmiCard(
            title: "Die Wurzeln arbeiten.",
            bodyText: "Zurück ab \(readyAt.formatted(date: .omitted, time: .shortened))."
        )
    }
}
