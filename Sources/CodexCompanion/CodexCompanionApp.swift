import AppKit
import CodexCompanionCore
import Foundation

@main
enum CodexCompanionMain {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let delegate = MenuBarController()
        app.delegate = delegate
        app.run()
    }
}

@MainActor
final class MenuBarController: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var storage: Storage!
    private var config: CompanionConfig!
    private var state = StoredState()
    private let client = AppServerClient()
    private var timer: Timer?
    private var lastError: String?
    private var dashboardWindow: NSWindow?
    private var dashboardView: CyberDashboardView?

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            storage = try Storage()
            config = try storage.loadConfig()
            state = try storage.loadState()
        } catch {
            lastError = error.localizedDescription
            config = CompanionConfig()
        }
        statusItem.button?.toolTip = "Codex Companion"
        createDashboard()
        rebuildMenu()
        refreshAll()
        showDashboard()
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(config.refreshIntervalSeconds), repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshAll() }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showDashboard()
        return true
    }

    private func refreshAll() {
        let accounts = config.accounts.filter(\.isEnabled)
        let previousState = state
        let persistence = storage!
        let client = client
        DispatchQueue.global(qos: .utility).async {
            var updated = previousState
            var errors: [String] = []
            for account in accounts {
                do { updated.snapshots[account.id] = try client.fetch(account: account) }
                catch { errors.append("\(account.displayName)：\(error.localizedDescription)") }
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.state = updated
                self.lastError = errors.isEmpty ? nil : ErrorSanitizer.displayMessage(errors.joined(separator: "\n"))
                try? persistence.save(updated)
                self.rebuildMenu()
            }
        }
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Codex Companion", action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        let now = Date()
        for account in config.accounts where account.isEnabled {
            menu.addItem(withTitle: account.displayName, action: nil, keyEquivalent: "")
            guard let snapshot = state.snapshots[account.id], snapshot.isFresh(at: now, staleAfterSeconds: config.staleAfterSeconds) else {
                menu.addItem(withTitle: "  暂无最新数据", action: nil, keyEquivalent: "")
                continue
            }
            add(window: snapshot.primary, fallbackLabel: "短周期", to: menu, now: now)
            add(window: snapshot.secondary, fallbackLabel: "长周期", to: menu, now: now)
            menu.addItem(withTitle: "  同步于 \(relative(snapshot.capturedAt, now: now))", action: nil, keyEquivalent: "")
        }
        menu.addItem(.separator())
        let recommendation = Recommender.recommend(profiles: config.accounts, snapshots: state.snapshots, now: now, staleAfterSeconds: config.staleAfterSeconds)
        menu.addItem(withTitle: recommendation.message, action: nil, keyEquivalent: "")
        if let lastError { menu.addItem(withTitle: "同步提示：\(lastError)", action: nil, keyEquivalent: "") }
        menu.addItem(.separator())
        menu.addItem(withTitle: "立即刷新", action: #selector(refreshAction), keyEquivalent: "r")
        menu.addItem(withTitle: "打开状态面板", action: #selector(showDashboard), keyEquivalent: "o")
        menu.addItem(withTitle: "打开配置文件", action: #selector(openConfig), keyEquivalent: ",")
        menu.addItem(withTitle: "退出", action: #selector(quit), keyEquivalent: "q")
        statusItem.menu = menu

        if let accountID = recommendation.accountID, let snapshot = state.snapshots[accountID], snapshot.isFresh(at: now, staleAfterSeconds: config.staleAfterSeconds), let primary = snapshot.primary {
            statusItem.button?.title = "C \(primary.remainingPercent)%"
        } else { statusItem.button?.title = "C ?" }
        updateDashboard(recommendation: recommendation, now: now)
    }

    private func add(window: RateLimitWindow?, fallbackLabel: String, to menu: NSMenu, now: Date) {
        guard let window else {
            menu.addItem(withTitle: "  \(fallbackLabel)：不可用", action: nil, keyEquivalent: "")
            return
        }
        let label = window.windowDurationMins.map(windowLabel) ?? fallbackLabel
        let reset = window.resetDate.map { " · \(countdown($0, now: now))" } ?? ""
        menu.addItem(withTitle: "  \(label)：可用 \(window.remainingPercent)%\(reset)", action: nil, keyEquivalent: "")
    }

    @objc private func refreshAction() { refreshAll() }
    @objc private func showDashboard() {
        dashboardWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    @objc private func openConfig() { NSWorkspace.shared.open(storage.configFileURL()) }
    @objc private func quit() { NSApp.terminate(nil) }

    private func windowLabel(_ minutes: Int) -> String {
        if minutes % 10_080 == 0 { return "周额度" }
        if minutes % 60 == 0 { return "\(minutes / 60)小时额度" }
        return "\(minutes)分钟额度"
    }

    private func countdown(_ date: Date, now: Date) -> String {
        let seconds = max(0, Int(date.timeIntervalSince(now)))
        return "\(seconds / 3600)小时\((seconds % 3600) / 60)分后重置"
    }

    private func relative(_ date: Date, now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        return seconds < 60 ? "刚刚" : "\(seconds / 60)分钟前"
    }

    private func createDashboard() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 840, height: 510),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Codex Companion"
        window.center()
        window.minSize = NSSize(width: 680, height: 450)
        let view = CyberDashboardView(frame: window.contentView?.bounds ?? .zero)
        view.autoresizingMask = [.width, .height]
        window.contentView = view
        dashboardWindow = window
        dashboardView = view
    }

    private func updateDashboard(recommendation: Recommendation, now: Date) {
        var cards: [CyberDashboardCard] = []
        for account in config.accounts where account.isEnabled {
            guard let snapshot = state.snapshots[account.id], snapshot.isFresh(at: now, staleAfterSeconds: config.staleAfterSeconds) else {
                cards.append(CyberDashboardCard(name: account.displayName, plan: "awaiting sync", shortLabel: "短周期", shortRemaining: nil, shortReset: "等待数据", longLabel: "长周期", longRemaining: nil, longReset: "等待数据", syncText: "NO FRESH SNAPSHOT", isRecommended: false))
                continue
            }
            let primary = snapshot.primary
            let secondary = snapshot.secondary
            cards.append(CyberDashboardCard(
                name: account.displayName,
                plan: snapshot.planType ?? "Codex profile",
                shortLabel: primary?.windowDurationMins.map(windowLabel) ?? "短周期",
                shortRemaining: primary?.remainingPercent,
                shortReset: primary?.resetDate.map { "RESET  \(countdown($0, now: now))" } ?? "RESET  —",
                longLabel: secondary?.windowDurationMins.map(windowLabel) ?? "长周期",
                longRemaining: secondary?.remainingPercent,
                longReset: secondary?.resetDate.map { "RESET  \(countdown($0, now: now))" } ?? "RESET  —",
                syncText: "SYNC  \(relative(snapshot.capturedAt, now: now))",
                isRecommended: recommendation.accountID == account.id
            ))
        }
        dashboardView?.cards = cards
        dashboardView?.recommendation = recommendation.message
        dashboardView?.diagnostic = lastError
    }
}
