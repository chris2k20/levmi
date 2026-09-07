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

    private var stored: PlayerState?

    public init() {}

    public func load() throws -> PlayerState? {
        stored
    }

    public func save(_ state: PlayerState) throws {
        stored = state
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
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(PlayerState.self, from: data)
    }

    public func save(_ state: PlayerState) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(state)
        try data.write(to: fileURL, options: .atomic)
    }
}
