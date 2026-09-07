import SwiftUI
import LevmiCore

// MARK: - GameView
//
// `ZStack` aus der 3D-Szene und dem phasengetriebenen Overlay (poc-spec §1, Architektur §3).
//
// `IslandSceneView` nimmt dieselbe `IslandWorld`-Instanz wie `SceneKitRenderer` entgegen (sonst
// laufen Effekt-Dispatch und Darstellung auf getrennten Szenen auseinander) und meldet Gesten über
// `IslandSceneHandlers` (1:1 `SceneEvent` aus LevmiCore). `breakthroughFinished` läuft NICHT über
// diese Handler, sondern direkt über `IslandWorld.onBreakthroughFinished` (von `AppModel`
// verdrahtet) — der Renderer kennt das Ende der eigenen Animation zuverlässiger als jede Geste.
// `onNodeHoldEnded(nodeID:completed:)` deckt sowohl `lightPlaced` (completed) als auch den
// Hinweistext nach abgebrochenen Holds (!completed) ab.

@MainActor
struct GameView: View {

    @Bindable var appModel: AppModel

    @State private var showFirstLightHint = false
    @State private var abortedHoldCount = 0
    @State private var showText1 = false
    @State private var showText2 = false
    @State private var showDayBadge = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            IslandSceneView(
                world: sceneWorld,
                handlers: IslandSceneHandlers(
                    onLightDropped: { appModel.send(.lightDropped) },
                    onNodeHoldEnded: { nodeID, completed in
                        if completed {
                            appModel.send(.lightPlaced(nodeID: nodeID))
                        } else {
                            abortedHoldCount += 1
                        }
                    },
                    onSunDragged: { progress in appModel.send(.sunPulled(progress)) },
                    onSunReleased: { progress in appModel.send(.sunPulled(progress)) }
                )
            )
            .ignoresSafeArea()
            .accessibilitySortPriority(1)

            VStack {
                Spacer()
                hintLine
                    .padding(.bottom, Theme.Spacing.xl)
                overlay
                    .padding(.bottom, Theme.Spacing.l)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .accessibilitySortPriority(3)

            if showDayBadge {
                DayBadge()
                    .accessibilitySortPriority(4)
            }

            if let banner = appModel.ownSentenceBanner {
                VStack {
                    OwnSentenceBanner(
                        sentence: banner.text,
                        date: banner.createdAt,
                        onDismiss: { appModel.dismissOwnSentenceBanner() }
                    )
                    .padding(.top, Theme.Spacing.m)
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.l)
                .accessibilitySortPriority(5)
            }

            #if DEBUG
            VStack {
                HStack {
                    Spacer()
                    DebugBar(isDemo: $appModel.isDemo, onReset: { appModel.send(.reset) })
                }
                Spacer()
            }
            .padding(Theme.Spacing.m)
            .accessibilitySortPriority(2)
            #endif
        }
        .task(id: appModel.state.phase) {
            await runFirstLightTimer()
        }
        .onChange(of: appModel.state.nodeOutcomes) { oldValue, newValue in
            guard newValue.count > oldValue.count, newValue.last == .lukewarm else { return }
            Task { await flashText2() }
        }
        .onChange(of: appModel.state.days) { oldValue, newValue in
            guard oldValue == 0, newValue == 1 else { return }
            showDayBadge = true
        }
        .onChange(of: appModel.state.phase) { _, newValue in
            abortedHoldCount = 0
            if newValue == .nodes { Task { await flashText1() } }
        }
    }

    private var sceneWorld: IslandWorld {
        (appModel.renderer as? SceneKitRenderer)?.world ?? IslandWorld()
    }

    // MARK: - Hinweiszeilen

    @ViewBuilder
    private var hintLine: some View {
        switch appModel.state.phase {
        case .firstLight:
            HintLine(text: "Zieh das Licht in den Nebel.", isVisible: showFirstLightHint)
        case .nodes:
            if showText1 {
                HintLine(text: "Du hast ein Licht.", isVisible: true)
            } else if showText2 {
                HintLine(text: "Das Lauwarme hat dein Licht gefressen.", isVisible: true)
            } else {
                HintLine(text: "Halten, bis der Ring voll ist.", isVisible: abortedHoldCount >= 2)
            }
        default:
            EmptyView()
        }
    }

    private func runFirstLightTimer() async {
        guard appModel.state.phase == .firstLight else { return }
        showFirstLightHint = false
        try? await Task.sleep(for: .seconds(7))
        guard !Task.isCancelled else { return }
        showFirstLightHint = true
    }

    private func flashText1() async {
        showText1 = true
        try? await Task.sleep(for: .seconds(2))
        withAnimation { showText1 = false }
    }

    private func flashText2() async {
        showText2 = true
        try? await Task.sleep(for: .seconds(2.5))
        withAnimation { showText2 = false }
    }

    // MARK: - Phasengetriebenes Overlay

    @ViewBuilder
    private var overlay: some View {
        switch appModel.state.phase {
        case .firstLight, .nodes, .roots, .breakthrough, .dawnProof, .idle:
            EmptyView()

        case .onboardingPain:
            PainTilesView(
                onFlipHaptic: { appModel.playTileFlipHaptic() },
                onContinue: { tiles in appModel.send(.painSelected(tiles)) }
            )

        case .onboardingWhy:
            TextEntryCard(
                title: "Wenn das wahr wäre — was wäre anders?",
                placeholder: "Ein Satz genügt",
                onSubmit: { text in appModel.send(.whyEntered(text.isEmpty ? nil : text)) },
                onSkip: { appModel.send(.whyEntered(nil)) }
            )

        case .intention:
            IntentionCard(now: appModel.clock.now) { text in
                let intention = Intention.make(
                    text: text,
                    principleID: "schnitt",
                    now: appModel.clock.now,
                    rules: appModel.rules
                )
                appModel.send(.intentionChosen(intention))
            }

        case .closed:
            ClosedCard(
                initialRemindMe: appModel.reminderEnabled,
                onReminderToggled: { appModel.setReminderEnabled($0) },
                onContinue: { appModel.send(.closeForToday) }
            )

        case .waiting:
            WaitingCard(readyAt: appModel.state.readyAt ?? appModel.clock.now)

        case .proof:
            TextEntryCard(
                eyebrow: appModel.state.intention?.text,
                title: "Hast du es getan?",
                placeholder: "Wer? Wann? Was ist passiert?",
                isMultiline: true,
                minCharsForReady: 40,
                submitLabel: "Senden",
                skipAllowed: false,
                rejectionMessage: appModel.rejectionReason,
                onReady: { ready in appModel.setSunGlimmer(ready) },
                onSubmit: { text in
                    appModel.clearRejection()
                    appModel.send(.proofSubmitted(text))
                }
            )

        case .cost:
            TextEntryCard(
                title: "Was war unangenehm daran?",
                placeholder: "Eine Zeile genügt",
                onSubmit: { text in appModel.send(.costEntered(text.isEmpty ? nil : text)) },
                onSkip: { appModel.send(.costEntered(nil)) }
            )

        case .befund:
            if let befund = appModel.state.befund {
                BefundCard(sentence: befund.sentence) { accepted in
                    appModel.send(.befundAnswered(accepted: accepted))
                }
            }
        }
    }
}
