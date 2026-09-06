import Foundation

// MARK: - Szenen-Vertrag (nur Datentypen, kein SceneKit)

public enum RootStrength: String, Codable, Equatable, Sendable {
    case thin, strong
}

public enum BreakthroughTier: String, Codable, Equatable, Sendable {
    case first, second
}

public enum SceneCommand: Equatable, Sendable {
    case presentLight
    case revealIsland
    case cameraPullBack
    case presentNodes([NodeKind])
    case chargeNode(NodeKind, progress: Double)
    case impact(NodeKind)
    case showRoots(RootStrength)
    case drainLight
    case thud
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
    case nodeHoldBegan(NodeKind)
    case nodeHoldEnded(NodeKind, completed: Bool)
    case sunDragged(Double)
    case sunReleased(Double)
}

/// Haptik-Signale. Cases aus den Reducer-Regeln 2–14 (poc-spec 3.2).
public enum HapticCue: String, Codable, Equatable, Sendable {
    case tap, impact, drain, flip, breakthrough
}

/// Ton-Signale. Cases aus den Reducer-Regeln 2–14 (poc-spec 3.2).
public enum SoundCue: String, Codable, Equatable, Sendable {
    case impact, lukewarm, cold, breakthrough
}
