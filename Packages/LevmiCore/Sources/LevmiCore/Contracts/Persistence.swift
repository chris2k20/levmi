import Foundation

// MARK: - Zeit

public protocol Clock: Sendable {
    var now: Date { get }
}

/// Echte Uhr. Trivial, deshalb bereits implementiert.
public struct SystemClock: Clock {
    public init() {}
    public var now: Date { Date() }
}

// MARK: - Persistenz

public protocol SaveStore {
    func load() throws -> PlayerState?
    func save(_ state: PlayerState) throws
}

public final class InMemorySaveStore: SaveStore {

    public init() {}

    public func load() throws -> PlayerState? {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
        return PlayerState()
    }

    public func save(_ state: PlayerState) throws {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
    }
}

public final class FileSaveStore: SaveStore {

    /// Dateiname im übergebenen Verzeichnis.
    public static let fileName = "levmi-state.json"

    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public var fileURL: URL {
        directory.appendingPathComponent(Self.fileName)
    }

    /// Liefert `nil`, wenn noch nichts gespeichert wurde. Unbekannte Felder im
    /// JSON dürfen das Laden nicht brechen.
    public func load() throws -> PlayerState? {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
        return PlayerState()
    }

    public func save(_ state: PlayerState) throws {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
    }
}
