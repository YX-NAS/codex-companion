import CodexCompanionCore
import Darwin
import Foundation

@main
enum CodexCompanionTestRunner {
    static func main() {
        let tests: [(String, () throws -> Void)] = [
            ("app-server response decoding", testDecoding),
            ("stale profile exclusion", testStaleRecommendation),
            ("exhausted short window exclusion", testExhaustedRecommendation),
            ("credential-shaped error redaction", testRedaction),
        ]
        var failures: [String] = []
        for (name, test) in tests {
            do {
                try test()
                print("PASS  \(name)")
            } catch {
                failures.append("FAIL  \(name): \(error.localizedDescription)")
            }
        }
        if failures.isEmpty {
            print("All \(tests.count) tests passed.")
        } else {
            failures.forEach { print($0) }
            exit(1)
        }
    }

    private static func testDecoding() throws {
        let data = Data("""
        {"id":2,"result":{"rateLimits":{"planType":"plus","primary":{"usedPercent":2,"windowDurationMins":300,"resetsAt":1783670558},"secondary":{"usedPercent":0,"windowDurationMins":10080,"resetsAt":1784257358},"rateLimitReachedType":null}}}
        """.utf8)
        let snapshot = try RateLimitDecoder.decode(accountID: "a", from: data, capturedAt: Date(timeIntervalSince1970: 0))
        try require(snapshot.planType == "plus", "plan type mismatch")
        try require(snapshot.primary?.remainingPercent == 98, "primary remaining mismatch")
        try require(snapshot.secondary?.windowDurationMins == 10_080, "secondary duration mismatch")
    }

    private static func testStaleRecommendation() throws {
        let now = Date(timeIntervalSince1970: 10_000)
        let fresh = UsageSnapshot(accountID: "fresh", capturedAt: now, primary: RateLimitWindow(usedPercent: 40, windowDurationMins: 300, resetsAt: nil), secondary: RateLimitWindow(usedPercent: 40, windowDurationMins: 10_080, resetsAt: nil))
        let stale = UsageSnapshot(accountID: "stale", capturedAt: now.addingTimeInterval(-901), primary: RateLimitWindow(usedPercent: 0, windowDurationMins: 300, resetsAt: nil), secondary: RateLimitWindow(usedPercent: 0, windowDurationMins: 10_080, resetsAt: nil))
        let result = Recommender.recommend(profiles: [AccountProfile(id: "fresh", displayName: "A"), AccountProfile(id: "stale", displayName: "B")], snapshots: ["fresh": fresh, "stale": stale], now: now, staleAfterSeconds: 900)
        try require(result.accountID == "fresh", "stale account was selected")
    }

    private static func testExhaustedRecommendation() throws {
        let now = Date()
        let exhausted = UsageSnapshot(accountID: "a", capturedAt: now, primary: RateLimitWindow(usedPercent: 95, windowDurationMins: 300, resetsAt: nil), secondary: RateLimitWindow(usedPercent: 0, windowDurationMins: 10_080, resetsAt: nil))
        let useful = UsageSnapshot(accountID: "b", capturedAt: now, primary: RateLimitWindow(usedPercent: 30, windowDurationMins: 300, resetsAt: nil), secondary: RateLimitWindow(usedPercent: 80, windowDurationMins: 10_080, resetsAt: nil))
        let result = Recommender.recommend(profiles: [AccountProfile(id: "a", displayName: "A"), AccountProfile(id: "b", displayName: "B")], snapshots: ["a": exhausted, "b": useful], now: now, staleAfterSeconds: 900)
        try require(result.accountID == "b", "account with unavailable short window was selected")
    }

    private static func testRedaction() throws {
        let value = ErrorSanitizer.displayMessage("request failed Authorization: Bearer secret-value token=another-secret")
        try require(!value.contains("secret-value") && !value.contains("another-secret"), "credential-shaped data was retained")
        try require(value.contains("[已隐藏]"), "redaction marker missing")
    }

    private static func require(_ condition: Bool, _ message: String) throws {
        if !condition { throw TestFailure(message: message) }
    }
}

private struct TestFailure: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
