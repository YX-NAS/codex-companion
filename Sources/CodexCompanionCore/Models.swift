import Foundation

public struct AccountProfile: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var displayName: String
    public var codexHome: String?
    public var isEnabled: Bool

    public init(id: String, displayName: String, codexHome: String? = nil, isEnabled: Bool = true) {
        self.id = id
        self.displayName = displayName
        self.codexHome = codexHome
        self.isEnabled = isEnabled
    }
}

public struct CompanionConfig: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var refreshIntervalSeconds: Int
    public var staleAfterSeconds: Int
    public var accounts: [AccountProfile]

    public init(
        schemaVersion: Int = 1,
        refreshIntervalSeconds: Int = 300,
        staleAfterSeconds: Int = 900,
        accounts: [AccountProfile] = [AccountProfile(id: "default", displayName: "当前 Codex 账号")]
    ) {
        self.schemaVersion = schemaVersion
        self.refreshIntervalSeconds = refreshIntervalSeconds
        self.staleAfterSeconds = staleAfterSeconds
        self.accounts = accounts
    }
}

public struct RateLimitWindow: Codable, Equatable, Sendable {
    public let usedPercent: Int
    public let windowDurationMins: Int?
    public let resetsAt: Int?

    public init(usedPercent: Int, windowDurationMins: Int?, resetsAt: Int?) {
        self.usedPercent = min(max(usedPercent, 0), 100)
        self.windowDurationMins = windowDurationMins
        self.resetsAt = resetsAt
    }

    public var remainingPercent: Int { 100 - usedPercent }
    public var resetDate: Date? { resetsAt.map { Date(timeIntervalSince1970: TimeInterval($0)) } }
}

public struct UsageSnapshot: Codable, Equatable, Sendable {
    public let accountID: String
    public let capturedAt: Date
    public let planType: String?
    public let primary: RateLimitWindow?
    public let secondary: RateLimitWindow?
    public let rateLimitReachedType: String?

    public init(
        accountID: String,
        capturedAt: Date = .now,
        planType: String? = nil,
        primary: RateLimitWindow?,
        secondary: RateLimitWindow?,
        rateLimitReachedType: String? = nil
    ) {
        self.accountID = accountID
        self.capturedAt = capturedAt
        self.planType = planType
        self.primary = primary
        self.secondary = secondary
        self.rateLimitReachedType = rateLimitReachedType
    }

    public func isFresh(at date: Date, staleAfterSeconds: Int) -> Bool {
        date.timeIntervalSince(capturedAt) <= TimeInterval(staleAfterSeconds)
    }
}

public struct StoredState: Codable, Equatable, Sendable {
    public var snapshots: [String: UsageSnapshot]

    public init(snapshots: [String: UsageSnapshot] = [:]) {
        self.snapshots = snapshots
    }
}
