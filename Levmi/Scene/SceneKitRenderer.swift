import LevmiCore
@preconcurrency import SceneKit

/// Rendering ausschließlich hinter diesem Protokoll — kein `SCNNode` in einer ViewModel-Signatur
/// (docs/strategy/03-engine-architekt.md §3 Punkt 2). `AppModel` kennt nur `SceneRenderer`/
/// `SceneCommand`, nie `IslandWorld` direkt.
protocol SceneRenderer: AnyObject {
    @MainActor func apply(_ command: SceneCommand)
}

/// Bindeglied zwischen der Domain (`SceneCommand` aus `LevmiCore`) und der SceneKit-Welt
/// (`IslandWorld`/`IslandChoreography`). Reine Verdrahtung: jeder `SceneCommand`-Fall ruft genau
/// eine Choreografie-Methode.
///
/// `init()` bleibt bewusst NICHT `@MainActor` und tut nichts: Default-Parameterwerte in Swift
/// müssen aus einem nonisolated Kontext aufrufbar sein (`AppModel.init(..., renderer: any
/// SceneRenderer = SceneKitRenderer())`), eine `@MainActor`-isolierte Klasse ließe sich dort nicht
/// instanziieren. `world` entsteht lazy beim ersten `apply(_:)`-Aufruf, der immer vom MainActor aus
/// kommt (`AppModel` ist `@MainActor`).
final class SceneKitRenderer: SceneRenderer {
    @MainActor private(set) lazy var world = IslandWorld()

    @MainActor var onBreakthroughFinished: (() -> Void)? {
        didSet { world.onBreakthroughFinished = onBreakthroughFinished }
    }

    init() {}

    @MainActor func apply(_ command: SceneCommand) {
        switch command {
        case .restore(let snapshot):
            world.restore(Self.map(snapshot))
        case .presentLight:
            world.presentLight()
        case .revealIsland:
            world.revealIsland()
        case .cameraPullBack:
            world.cameraPullBack()
        case .presentNodes(let specs):
            world.presentNodes(specs.map { (id: $0.id, kind: $0.kind.rawValue) })
        case .impact(let nodeID):
            world.impact(nodeID: nodeID)
        case .showRoots(let nodeID, let strength):
            world.showRoots(nodeID: nodeID, strong: strength == .strong)
        case .drainLight(let nodeID):
            world.drainLight(nodeID: nodeID)
        case .thud(let nodeID):
            world.thud(nodeID: nodeID)
        case .hintGlowing:
            world.hintGlowing()
        case .presentSun:
            world.presentSun()
        case .sunProgress(let progress):
            world.sunProgress(progress)
        case .dawn:
            world.dawn()
        case .breakthrough(let tier):
            world.breakthrough(tier: tier.rawValue)
        case .tintLight(let tile):
            world.tintLight(hex: tile.map(Self.hex(for:)))
        case .rootWindow(let visible):
            world.rootWindow(visible: visible)
        case .fogLevel(let level):
            world.fogLevel(level)
        }
    }

    /// `SceneSnapshot.litNodeIDs`/`.roots` sind parallele Arrays (gleiche Reihenfolge, gleiche
    /// Länge) — nur gesetzte Knoten (glowing/lukewarm) tragen eine Wurzelstärke, cold nie.
    @MainActor private static func map(_ snapshot: SceneSnapshot) -> IslandWorld.Snapshot {
        IslandWorld.Snapshot(
            islandRevealed: snapshot.islandRevealed,
            nodes: snapshot.nodes.map { IslandWorld.Snapshot.NodeSpec(id: $0.id, kind: $0.kind.rawValue) },
            litNodeIDs: Set(snapshot.litNodeIDs),
            roots: zip(snapshot.litNodeIDs, snapshot.roots).map {
                IslandWorld.Snapshot.RootState(nodeID: $0, strong: $1 == .strong)
            },
            lightVisible: snapshot.lightVisible,
            sunVisible: snapshot.sunVisible,
            sunProgress: snapshot.sunProgress,
            fogLevel: snapshot.fogLevel,
            lightTint: snapshot.lightTile.map(hex(for:)),
            rootWindow: snapshot.rootWindow,
            breakthroughTier: snapshot.breakthroughTier?.rawValue
        )
    }

    /// Lichtfarbe je Schmerz-Kachel (poc-spec 1.2.3: "Farbton aus der ersten gewählten Kachel").
    /// Die Zuordnung selbst ist reine Optik und lebt bewusst hier, nicht in `LevmiCore`.
    private static func hex(for tile: PainTile) -> String {
        switch tile {
        case .zeitWeg: return "#FFB347"
        case .zuVielLauwarmes: return "#FF6FA8"
        case .keinFortschritt: return "#7FE7FF"
        case .geldReichtNicht: return "#FFD37A"
        case .immerErreichbar: return "#9B8CFF"
        case .allesHaengtAnMir: return "#FF8A5B"
        }
    }
}
