import Foundation

public final class AppServerClient: @unchecked Sendable {
    private let codexExecutable: String
    private let timeout: TimeInterval

    public init(codexExecutable: String = "/Applications/ChatGPT.app/Contents/Resources/codex", timeout: TimeInterval = 12) {
        self.codexExecutable = FileManager.default.isExecutableFile(atPath: codexExecutable) ? codexExecutable : "codex"
        self.timeout = timeout
    }

    public func fetch(account: AccountProfile) throws -> UsageSnapshot {
        let process = Process()
        let input = Pipe()
        let output = Pipe()
        let error = Pipe()
        process.executableURL = URL(fileURLWithPath: codexExecutable)
        process.arguments = ["-s", "read-only", "-a", "untrusted", "app-server"]
        var environment = ProcessInfo.processInfo.environment
        if let home = account.codexHome, !home.isEmpty {
            environment["CODEX_HOME"] = (home as NSString).expandingTildeInPath
        }
        process.environment = environment
        process.standardInput = input
        process.standardOutput = output
        process.standardError = error
        do { try process.run() } catch { throw CompanionError.codexUnavailable }
        defer { if process.isRunning { process.terminate() } }

        let initialize: [String: Any] = [
            "id": 1,
            "method": "initialize",
            "params": ["clientInfo": ["name": "CodexCompanion", "version": "0.1.5"], "capabilities": [:]],
        ]
        try write(initialize, to: input)
        _ = try readResponse(id: 1, from: output, error: error)
        try write(["id": 2, "method": "account/rateLimits/read", "params": [:]], to: input)
        let response = try readResponse(id: 2, from: output, error: error)
        return try RateLimitDecoder.decode(accountID: account.id, from: response)
    }

    private func write(_ object: [String: Any], to pipe: Pipe) throws {
        let data = try JSONSerialization.data(withJSONObject: object)
        pipe.fileHandleForWriting.write(data)
        pipe.fileHandleForWriting.write(Data([0x0A]))
    }

    private func readResponse(id: Int, from output: Pipe, error: Pipe) throws -> Data {
        let deadline = Date().addingTimeInterval(timeout)
        var buffer = Data()
        while Date() < deadline {
            let available = output.fileHandleForReading.availableData
            if available.isEmpty { break }
            buffer.append(available)
            while let newline = buffer.firstIndex(of: 0x0A) {
                let line = buffer.prefix(upTo: newline)
                buffer.removeSubrange(...newline)
                guard !line.isEmpty,
                      let object = try? JSONSerialization.jsonObject(with: line) as? [String: Any]
                else { continue }
                if let responseID = object["id"] as? Int, responseID == id {
                    if let failure = object["error"] as? [String: Any] {
                        throw CompanionError.appServerError((failure["message"] as? String) ?? "未知错误")
                    }
                    return Data(line)
                }
            }
        }
        let errorData = error.fileHandleForReading.availableData
        if let message = String(data: errorData, encoding: .utf8), !message.isEmpty {
            throw CompanionError.appServerError(message.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        throw CompanionError.appServerTimedOut
    }
}
