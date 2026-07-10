import Foundation

public struct Recommendation: Equatable, Sendable {
    public let accountID: String?
    public let message: String
    public let score: Double?

    public init(accountID: String?, message: String, score: Double?) {
        self.accountID = accountID
        self.message = message
        self.score = score
    }
}

public enum Recommender {
    public static func recommend(
        profiles: [AccountProfile],
        snapshots: [String: UsageSnapshot],
        now: Date = .now,
        staleAfterSeconds: Int
    ) -> Recommendation {
        let candidates = profiles.compactMap { profile -> (AccountProfile, UsageSnapshot, Double)? in
            guard profile.isEnabled,
                  let snapshot = snapshots[profile.id],
                  snapshot.isFresh(at: now, staleAfterSeconds: staleAfterSeconds),
                  let primary = snapshot.primary,
                  let secondary = snapshot.secondary,
                  primary.remainingPercent >= 10
            else { return nil }
            let score = Double(primary.remainingPercent) * 0.7 + Double(secondary.remainingPercent) * 0.3
            return (profile, snapshot, score)
        }.sorted { $0.2 > $1.2 }

        guard let best = candidates.first else {
            return Recommendation(accountID: nil, message: "没有可用的最新额度数据；请刷新账号。", score: nil)
        }
        guard candidates.count > 1, let next = candidates.dropFirst().first else {
            return Recommendation(accountID: best.0.id, message: "建议使用 \(best.0.displayName)。", score: best.2)
        }
        if best.2 - next.2 < 10 {
            return Recommendation(accountID: best.0.id, message: "两个账号额度接近，建议继续使用当前账号。", score: best.2)
        }
        let shortDifference = best.1.primary!.remainingPercent - next.1.primary!.remainingPercent
        let longDifference = best.1.secondary!.remainingPercent - next.1.secondary!.remainingPercent
        return Recommendation(
            accountID: best.0.id,
            message: "建议使用 \(best.0.displayName)：短周期多 \(shortDifference)%、长周期多 \(longDifference)% 。",
            score: best.2
        )
    }
}
