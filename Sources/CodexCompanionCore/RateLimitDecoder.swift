import Foundation

public enum RateLimitDecoder {
    private struct RPCEnvelope: Decodable {
        let result: ResultPayload?
    }

    private struct ResultPayload: Decodable {
        let rateLimits: RateLimits
    }

    private struct RateLimits: Decodable {
        let planType: String?
        let primary: RateLimitWindow?
        let secondary: RateLimitWindow?
        let rateLimitReachedType: String?
    }

    public static func decode(accountID: String, from line: Data, capturedAt: Date = .now) throws -> UsageSnapshot {
        let envelope = try JSONDecoder().decode(RPCEnvelope.self, from: line)
        guard let limits = envelope.result?.rateLimits else {
            throw CompanionError.invalidRateLimitResponse
        }
        return UsageSnapshot(
            accountID: accountID,
            capturedAt: capturedAt,
            planType: limits.planType,
            primary: limits.primary,
            secondary: limits.secondary,
            rateLimitReachedType: limits.rateLimitReachedType
        )
    }
}

public enum CompanionError: LocalizedError, Equatable {
    case codexUnavailable
    case appServerTimedOut
    case invalidRateLimitResponse
    case appServerError(String)

    public var errorDescription: String? {
        switch self {
        case .codexUnavailable: "未找到 Codex CLI。"
        case .appServerTimedOut: "Codex 用量读取超时。"
        case .invalidRateLimitResponse: "Codex 返回的用量数据无法识别。"
        case let .appServerError(message): "Codex 用量读取失败：\(message)"
        }
    }
}
