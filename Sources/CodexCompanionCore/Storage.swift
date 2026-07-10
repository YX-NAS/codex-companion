import Foundation

public final class Storage: @unchecked Sendable {
    public let baseDirectory: URL
    private let configURL: URL
    private let stateURL: URL
    private let encoder: JSONEncoder
    private let decoder = JSONDecoder()

    public init(baseDirectory: URL? = nil) throws {
        let root = try baseDirectory ?? Self.defaultDirectory()
        self.baseDirectory = root
        self.configURL = root.appendingPathComponent("config.json")
        self.stateURL = root.appendingPathComponent("state.json")
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    public func loadConfig() throws -> CompanionConfig {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            let config = CompanionConfig()
            try save(config)
            return config
        }
        return try decoder.decode(CompanionConfig.self, from: Data(contentsOf: configURL))
    }

    public func save(_ config: CompanionConfig) throws {
        try encoder.encode(config).write(to: configURL, options: .atomic)
    }

    public func loadState() throws -> StoredState {
        guard FileManager.default.fileExists(atPath: stateURL.path) else { return StoredState() }
        return try decoder.decode(StoredState.self, from: Data(contentsOf: stateURL))
    }

    public func save(_ state: StoredState) throws {
        try encoder.encode(state).write(to: stateURL, options: .atomic)
    }

    public func configFileURL() -> URL { configURL }

    private static func defaultDirectory() throws -> URL {
        guard let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw CompanionError.appServerError("无法确定 Application Support 目录。")
        }
        return root.appendingPathComponent("CodexCompanion", isDirectory: true)
    }
}
