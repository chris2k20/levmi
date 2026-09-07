import Foundation

// MARK: - Szenen-Vertrag (nur Datentypen, kein SceneKit)

public enum RootStrength: String, Codable, Sendable, Equatable {
    case strong
    case weak
}

public enum BreakthroughTier: String, Codable, Sendable, Equatable {
    case full, half, thin, second
}

/// Vollständiges Bild der Szene, aus dem der Renderer ohne Animation wiederherstellt.
public struct SceneSnapshot: Codable, Sendable, Equatable {
    public var islandRevealed: Bool
    public var nodes: [NodeSpec]
    public var litNodeIDs: [Int]
    public var roots: [RootStrength]
    public var lightVisible: Bool
    public var sunProgress: Double
    public var sunVisible: Bool
    public var fogLevel: Int
    public var lightTile: PainTile?
    public var rootWindow: Bool
    public var breakthroughTier: BreakthroughTier?

    public init(
        islandRevealed: Bool = false,
        nodes: [NodeSpec] = [],
        litNodeIDs: [Int] = [],
        roots: [RootStrength] = [],
        lightVisible: Bool = false,
        sunProgress: Double = 0,
        sunVisible: Bool = false,
        fogLevel: Int = 0,
        lightTile: PainTile? = nil,
        rootWindow: Bool = false,
        breakthroughTier: BreakthroughTier? = nil
    ) {
        self.islandRevealed = islandRevealed
        self.nodes = nodes
        self.litNodeIDs = litNodeIDs
        self.roots = roots
        self.lightVisible = lightVisible
        self.sunProgress = sunProgress
        self.sunVisible = sunVisible
        self.fogLevel = fogLevel
        self.lightTile = lightTile
        self.rootWindow = rootWindow
        self.breakthroughTier = breakthroughTier
    }
}

/// Reine Funktion Zustand → Szene. Regeln in poc-spec 3.3:
/// Insel sichtbar ab Phase ≥ `nodes`; Knoten aus `nodes`, gesetzte aus `litNodeIDs`
/// mit Wurzelstärke aus `placements` (glowing → `.strong`, lukewarm → `.weak`, cold → keine Wurzel);
/// Licht sichtbar in `firstLight`/`nodes`, wenn `lightsRemaining > 0`;
/// Sonne sichtbar in `roots`/`dawnProof` mit `sunProgress`, in `waiting` unter dem Horizont;
/// Wurzelfenster in `waiting`; `fogLevel = days > 0 ? 1 : 0`; Lichtfarbe aus `lightColorTile`.
public enum SceneProjection {

    public static func snapshot(of state: PlayerState) -> SceneSnapshot {
        let roots: [RootStrength] = state.litNodeIDs.map { id in
            switch state.placements.first(where: { $0.nodeID == id })?.kind {
            case .glowing: return .strong
            default: return .weak
            }
        }
        return SceneSnapshot(
            islandRevealed: state.phase != .firstLight,
            nodes: state.nodes,
            litNodeIDs: state.litNodeIDs,
            roots: roots,
            lightVisible: (state.phase == .firstLight || state.phase == .nodes) && state.lightsRemaining > 0,
            sunProgress: state.sunProgress,
            sunVisible: [.roots, .breakthrough, .dawnProof, .breakthroughProof].contains(state.phase),
            fogLevel: state.days > 0 ? 1 : 0,
            lightTile: state.lightColorTile,
            rootWindow: state.phase == .waiting,
            breakthroughTier: breakthroughTier(for: state, strongRoots: roots.filter { $0 == .strong }.count)
        )
    }

    /// Review-Befund 3: Nach App-Kill in einer Durchbruch-Phase muss der Renderer den Trieb zeigen können.
    static func breakthroughTier(for state: PlayerState, strongRoots: Int) -> BreakthroughTier? {
        switch state.phase {
        case .breakthrough:
            return strongRoots >= 2 ? .full : (strongRoots == 1 ? .half : .thin)
        case .breakthroughProof:
            return .second
        default:
            return nil
        }
    }
}

public enum SceneCommand: Equatable, Sendable {
    case restore(SceneSnapshot)
    case presentLight
    case revealIsland
    case cameraPullBack
    case presentNodes([NodeSpec])
    case impact(nodeID: Int)
    case showRoots(nodeID: Int, RootStrength)
    case drainLight(nodeID: Int)
    case thud(nodeID: Int)
    case hintGlowing
    case presentSun
    case sunProgress(Double)
    case dawn
    case breakthrough(BreakthroughTier)
    case tintLight(PainTile?)
    case rootWindow(visible: Bool)
    case fogLevel(Int)
}

public enum SceneEvent: Sendable {
    case lightDropped
    case nodeHoldBegan(nodeID: Int)
    case nodeHoldEnded(nodeID: Int, completed: Bool)
    case sunDragged(Double)
    case sunReleased(Double)
    case breakthroughFinished
}

public enum HapticCue: Equatable, Sendable {
    case tap, flip, impact, drain, breakthrough
}

public enum SoundCue: Equatable, Sendable {
    case impact
    case node(NodeKind)
    case drain
    case breakthrough
}
