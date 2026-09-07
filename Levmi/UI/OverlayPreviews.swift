import SwiftUI
import LevmiCore

// MARK: - OverlayPreviews
//
// `#Preview`s für alle Karten auf dunklem Hintergrund (Nebelmeer). Solange `GameEngine` noch Stub
// ist, sind das die einzige Art, die Karten zu prüfen — siehe poc-spec §0/§3.2.

private struct PreviewBackground<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.Color.fogSea, Theme.Color.fogHorizon],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            content()
                .padding(Theme.Spacing.l)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview("LevmiCard — generisch") {
    PreviewBackground {
        LevmiCard(
            eyebrow: "Beispiel",
            title: "Eine Karte, viele Konfigurationen.",
            bodyText: "Der Fließtext erklärt kurz, worum es geht.",
            footnote: "Bleibt auf deinem Gerät.",
            primary: LevmiCardButton(title: "Weiter", action: {}),
            secondary: LevmiCardButton(title: "Überspringen", action: {})
        )
    }
}

#Preview("HintLine") {
    PreviewBackground {
        VStack {
            Spacer()
            HintLine(text: "Zieh das Licht in den Nebel.", isVisible: true)
            Spacer().frame(height: 60)
        }
    }
}

#Preview("PainTilesView") {
    PreviewBackground {
        PainTilesView(onFlipHaptic: {}, onContinue: { _ in })
    }
}

#Preview("TextEntryCard — Wofür?") {
    PreviewBackground {
        TextEntryCard(
            title: "Wenn das wahr wäre — was wäre anders?",
            placeholder: "Ein Satz genügt",
            onSubmit: { _ in },
            onSkip: {}
        )
    }
}

#Preview("TextEntryCard — Beweis") {
    PreviewBackground {
        TextEntryCard(
            title: "Hast du es getan?",
            placeholder: "Wer? Wann? Was ist passiert?",
            isMultiline: true,
            minCharsForReady: 40,
            submitLabel: "Senden",
            skipAllowed: false,
            rejectionMessage: "Konkreter: Wer, wann, was ist passiert?",
            onReady: { _ in },
            onSubmit: { _ in }
        )
    }
}

#Preview("TextEntryCard — Kosten") {
    PreviewBackground {
        TextEntryCard(
            title: "Was war unangenehm daran?",
            placeholder: "Eine Zeile genügt",
            onSubmit: { _ in },
            onSkip: {}
        )
    }
}

#Preview("IntentionCard") {
    PreviewBackground {
        IntentionCard(onChoose: { _ in })
    }
}

#Preview("ClosedCard") {
    PreviewBackground {
        ClosedCard(onReminderToggled: { _ in }, onContinue: {})
    }
}

#Preview("WaitingCard") {
    PreviewBackground {
        WaitingCard(readyAt: Date().addingTimeInterval(600))
    }
}

#Preview("DayBadge") {
    PreviewBackground {
        DayBadge()
    }
}

#Preview("BefundCard") {
    PreviewBackground {
        BefundCard(
            sentence: "Du hast \u{201E}Zu viel Lauwarmes\u{201C} angekreuzt — und heute Nacht trotzdem zweimal Lauwarmes gefüttert.",
            onAnswer: { _ in }
        )
    }
}

#Preview("OwnSentenceBanner") {
    PreviewBackground {
        VStack {
            OwnSentenceBanner(
                sentence: "Ich sage bis Freitag zwei lauwarmen Terminen ab.",
                date: Date().addingTimeInterval(-86_400),
                onDismiss: {}
            )
            Spacer()
        }
    }
}

#if DEBUG
private struct DebugBarPreviewHost: View {
    @State private var isDemo = true
    var body: some View {
        DebugBar(isDemo: $isDemo, onReset: {})
    }
}

#Preview("DebugBar") {
    PreviewBackground {
        VStack {
            HStack {
                Spacer()
                DebugBarPreviewHost()
            }
            Spacer()
        }
    }
}
#endif
