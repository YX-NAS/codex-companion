import AppKit
import CodexCompanionCore
import Foundation

@main
enum CodexCompanionMain {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
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
    private let popover = NSPopover()
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
        configureStatusPopover()
        rebuildMenu()
        refreshAll()
        togglePopover()
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(config.refreshIntervalSeconds), repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshAll() }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        togglePopover()
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
        let now = Date()
        let recommendation = Recommender.recommend(profiles: config.accounts, snapshots: state.snapshots, now: now, staleAfterSeconds: config.staleAfterSeconds)
        if let accountID = recommendation.accountID, let snapshot = state.snapshots[accountID], snapshot.isFresh(at: now, staleAfterSeconds: config.staleAfterSeconds), let primary = snapshot.primary {
            statusItem.button?.title = "◈ \(primary.remainingPercent)%"
        } else { statusItem.button?.title = "◈ —" }
        updateDashboard(recommendation: recommendation, now: now)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            refreshAll()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    @objc private func refreshAction() {
        if let updatedConfig = try? storage.loadConfig() {
            config = updatedConfig
        }
        refreshAll()
    }

    @objc private func openConfig() {
        NSWorkspace.shared.open(storage.configFileURL())
    }

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

    private func configureStatusPopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 360, height: 474)
        let controller = NSViewController()
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 474))
        let view = CyberDashboardView(frame: NSRect(x: 0, y: 0, width: 360, height: 430))
        root.addSubview(view)
        let refresh = NSButton(title: "↻  刷新额度", target: self, action: #selector(refreshAction))
        refresh.frame = NSRect(x: 22, y: 438, width: 145, height: 26)
        refresh.bezelStyle = .rounded
        refresh.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
        let settings = NSButton(title: "⚙  账号设置", target: self, action: #selector(openConfig))
        settings.frame = NSRect(x: 193, y: 438, width: 145, height: 26)
        settings.bezelStyle = .rounded
        settings.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
        root.addSubview(refresh)
        root.addSubview(settings)
        controller.view = root
        popover.contentViewController = controller
        dashboardView = view
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.sendAction(on: [.leftMouseUp])
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
        if let recommended = cards.first(where: { $0.isRecommended }) {
            dashboardView?.cards = [recommended]
        } else {
            dashboardView?.cards = Array(cards.prefix(1))
        }
        dashboardView?.recommendation = recommendation.message
        dashboardView?.diagnostic = lastError
    }
}
