import SwiftUI

/// TEMPORÄRE Demo-Ansicht (kein Produktcode): spielt die Choreografie ohne Domain in der
/// geforderten festen Sequenz durch — presentLight → revealIsland → cameraPullBack → presentNodes
/// → chargeNode/impact → showRoots → presentSun → sunProgress → dawn → breakthrough — inklusive
/// Haptik und Audio, per Button oder Auto-Timer. Zusätzlich demonstriert sie das korrigierte
/// Design (fünf Knoten, zwei Lichter/Nacht, lauwarm ohne Vorwarnung) und ist gleichzeitig voll
/// spielbar: echte Gesten (Licht ziehen, Knoten halten, Sonne ziehen) laufen über dieselbe
/// `IslandSceneHandlers`-Schnittstelle wie später die Domain. Wird gelöscht, sobald `AppModel`
/// diesen Platz einnimmt.
struct IslandDemoView: View {
    @State private var world = IslandWorld()
    @State private var haptics = HapticsPlayer()
    @State private var audio = ProceduralAudio()
    @State private var stepLabel = "bereit"
    @State private var autoPlay = false
    @State private var currentStep = Step.start
    @State private var sceneID = UUID()
    @State private var rootWindowOn = false
    @State private var tinted = false
    @State private var fogStep = 0

    private let nodeSpecs: [(id: Int, kind: String)] = [
        (0, "glowing"), (1, "lukewarm"), (2, "cold"), (3, "glowing"), (4, "lukewarm"),
    ]

    private enum Step: Int, CaseIterable {
        case start, presentLight, revealIsland, cameraPullBack, presentNodes
        case chargeGlowing, secondLight, chargeLukewarm, thirdLight
        case presentSun, sunProgress, breakthrough, done

        var title: String {
            switch self {
            case .start: return "bereit"
            case .presentLight: return "presentLight"
            case .revealIsland: return "revealIsland"
            case .cameraPullBack: return "cameraPullBack"
            case .presentNodes: return "presentNodes (5 Knoten)"
            case .chargeGlowing: return "chargeNode → impact → showRoots(strong)"
            case .secondLight: return "presentLight (2. Licht) + hintGlowing"
            case .chargeLukewarm: return "chargeNode → drainLight"
            case .thirdLight: return "presentLight (Ersatzlicht)"
            case .presentSun: return "presentSun"
            case .sunProgress: return "sunProgress → dawn"
            case .breakthrough: return "breakthrough(tier: full)"
            case .done: return "+1 Tag"
            }
        }
    }

    private var handlers: IslandSceneHandlers {
        IslandSceneHandlers(
            onLightDropped: { runRevealSequence() },
            onNodeHoldBegan: { _ in haptics.tap() },
            onNodeHoldEnded: { id, completed in handleNodeHoldEnded(nodeID: id, completed: completed) },
            onSunDragged: { progress in haptics.chargeRamp(progress: progress) },
            onSunReleased: { progress in
                haptics.endChargeRamp()
                if progress >= 0.999 { runDawnAndBreakthrough() }
            }
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            IslandSceneView(world: world, handlers: handlers)
                .ignoresSafeArea()
                .id(sceneID)

            VStack(spacing: 8) {
                Text(stepLabel)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Button("Weiter") { advanceScripted() }
                    Toggle("Auto", isOn: $autoPlay).toggleStyle(.button)
                    Button("Neu") { reset() }
                }

                HStack(spacing: 8) {
                    Button(rootWindowOn ? "Wurzelfenster aus" : "Wurzelfenster an") {
                        rootWindowOn.toggle()
                        world.rootWindow(visible: rootWindowOn)
                    }
                    Button(tinted ? "Licht: Standard" : "Licht: Rosa") {
                        tinted.toggle()
                        world.tintLight(hex: tinted ? "#FF6FA8" : nil)
                    }
                    Button("Nebel −") {
                        fogStep = min(3, fogStep + 1)
                        world.fogLevel(fogStep)
                    }
                }
                .font(.caption)
            }
            .font(.footnote.bold())
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.black.opacity(0.55), in: .rect(cornerRadius: 16))
            .padding(.bottom, 20)
        }
        .onAppear {
            audio.startDrone()
            performStep(.presentLight)
        }
        .onReceive(Timer.publish(every: 2.4, on: .main, in: .common).autoconnect()) { _ in
            guard autoPlay else { return }
            advanceScripted()
        }
    }

    // MARK: - Feste Sequenz

    private func advanceScripted() {
        guard let next = Step(rawValue: currentStep.rawValue + 1) else { return }
        performStep(next)
    }

    private func performStep(_ step: Step) {
        currentStep = step
        stepLabel = step.title
        switch step {
        case .start, .done:
            break
        case .presentLight:
            world.presentLight()
            haptics.tap()
        case .revealIsland:
            world.revealIsland()
            haptics.impact()
            audio.playImpact()
        case .cameraPullBack:
            world.cameraPullBack()
        case .presentNodes:
            world.presentNodes(nodeSpecs)
        case .chargeGlowing:
            simulateHold(nodeID: 0)
        case .secondLight:
            world.hintGlowing()
            world.presentLight()
            haptics.tap()
        case .chargeLukewarm:
            simulateHold(nodeID: 1)
        case .thirdLight:
            world.presentLight()
            haptics.tap()
        case .presentSun:
            world.presentSun()
        case .sunProgress:
            animateSunProgress()
        case .breakthrough:
            triggerBreakthrough(tier: "full")
        }
    }

    /// Reagiert auf einen echten Licht-Drop (Geste) genau wie die Domain es täte: revealIsland,
    /// dann cameraPullBack, dann presentNodes — zeitlich gestaffelt statt alles auf einmal.
    private func runRevealSequence() {
        performStep(.revealIsland)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { performStep(.cameraPullBack) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) { performStep(.presentNodes) }
    }

    private func runDawnAndBreakthrough() {
        world.dawn()
        triggerBreakthrough(tier: "full")
    }

    private func triggerBreakthrough(tier: String) {
        currentStep = .breakthrough
        stepLabel = Step.breakthrough.title
        world.onBreakthroughFinished = { stepLabel = Step.done.title }
        world.breakthrough(tier: tier)
        haptics.breakthrough()
        audio.playBreakthrough()
    }

    /// Simuliert einen ~1,1-s-Hold auf `nodeID` (für den Auto-Demo-Button — echte Holds laufen über
    /// `IslandSceneView`s Gesten und `handleNodeHoldEnded`).
    private func simulateHold(nodeID: Int) {
        haptics.tap()
        let steps = 22
        let duration = 1.1
        for i in 0...steps {
            let delay = duration * Double(i) / Double(steps)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let progress = Double(i) / Double(steps)
                world.chargeNode(kind: nodeID, progress: progress)
                haptics.chargeRamp(progress: progress)
                if i == steps {
                    haptics.endChargeRamp()
                    resolveHold(nodeID: nodeID)
                }
            }
        }
    }

    private func handleNodeHoldEnded(nodeID: Int, completed: Bool) {
        guard completed else {
            haptics.endChargeRamp()
            return // Ring ist bereits sichtbar zurückgefallen (siehe chargeNode-Aufrufe der Geste)
        }
        haptics.endChargeRamp()
        resolveHold(nodeID: nodeID)
    }

    private func resolveHold(nodeID: Int) {
        switch world.nodeFamilies[nodeID] ?? "cold" {
        case "glowing":
            world.impact(nodeID: nodeID)
            haptics.impact()
            audio.playNodeTone("glowing")
            world.showRoots(nodeID: nodeID, strong: true)
        case "lukewarm":
            audio.playNodeTone("lukewarm")
            world.drainLight(nodeID: nodeID)
            haptics.drain()
            audio.playDrain()
        default:
            world.thud(nodeID: nodeID)
            haptics.tap()
            audio.playNodeTone("cold")
        }
    }

    private func animateSunProgress() {
        let steps = 24
        let duration = 1.2
        for i in 0...steps {
            let delay = duration * Double(i) / Double(steps)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let progress = Double(i) / Double(steps)
                world.sunProgress(progress)
                if i == steps {
                    world.dawn()
                    currentStep = .sunProgress
                }
            }
        }
    }

    private func reset() {
        rootWindowOn = false
        tinted = false
        fogStep = 0
        world = IslandWorld()
        sceneID = UUID()
        currentStep = .start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            performStep(.presentLight)
        }
    }
}

#Preview { IslandDemoView() }
