import AppKit

struct CyberDashboardCard {
    let name: String
    let plan: String
    let shortLabel: String
    let shortRemaining: Int?
    let shortReset: String
    let longLabel: String
    let longRemaining: Int?
    let longReset: String
    let syncText: String
    let isRecommended: Bool
}

final class CyberDashboardView: NSView {
    var cards: [CyberDashboardCard] = [] { didSet { needsDisplay = true } }
    var recommendation = "正在读取额度数据…" { didSet { needsDisplay = true } }
    var diagnostic: String? { didSet { needsDisplay = true } }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let bounds = self.bounds
        NSGradient(
            starting: NSColor(red: 0.025, green: 0.035, blue: 0.10, alpha: 1),
            ending: NSColor(red: 0.10, green: 0.025, blue: 0.18, alpha: 1)
        )?.draw(in: bounds, angle: 135)
        drawGrid(in: bounds)
        drawHeader(in: bounds)
        drawCards(in: bounds)
        drawRecommendation(in: bounds)
    }

    private func drawGrid(in bounds: NSRect) {
        NSColor.cyan.withAlphaComponent(0.045).setStroke()
        let path = NSBezierPath()
        let spacing: CGFloat = 28
        for x in stride(from: 0, through: bounds.width, by: spacing) {
            path.move(to: NSPoint(x: x, y: 0))
            path.line(to: NSPoint(x: x, y: bounds.height))
        }
        for y in stride(from: 0, through: bounds.height, by: spacing) {
            path.move(to: NSPoint(x: 0, y: y))
            path.line(to: NSPoint(x: bounds.width, y: y))
        }
        path.lineWidth = 0.5
        path.stroke()
    }

    private func drawHeader(in bounds: NSRect) {
        let compact = bounds.width < 500
        text("CODEX // COMPANION", at: NSPoint(x: 22, y: 25), font: .systemFont(ofSize: compact ? 18 : 22, weight: .bold), color: .white)
        text("NEON QUOTA CONTROL", at: NSPoint(x: 34, y: 54), font: .monospacedSystemFont(ofSize: 10, weight: .medium), color: .cyan)
        let liveRect = NSRect(x: bounds.width - (compact ? 98 : 126), y: 28, width: compact ? 76 : 92, height: 26)
        rounded(liveRect, radius: 13, fill: NSColor.cyan.withAlphaComponent(0.13), stroke: .cyan.withAlphaComponent(0.9), lineWidth: 1)
        text(compact ? "● LIVE" : "●  LIVE", at: NSPoint(x: liveRect.minX + (compact ? 10 : 15), y: liveRect.minY + 7), font: .monospacedSystemFont(ofSize: 10, weight: .bold), color: .cyan)
        NSColor.cyan.withAlphaComponent(0.65).setStroke()
        let line = NSBezierPath()
        line.move(to: NSPoint(x: 32, y: 82))
        line.line(to: NSPoint(x: bounds.width - 32, y: 82))
        line.lineWidth = 1
        line.stroke()
    }

    private func drawCards(in bounds: NSRect) {
        let visibleCards = Array(cards.prefix(1))
        let count = max(visibleCards.count, 1)
        let gap: CGFloat = 18
        let totalWidth = bounds.width - 64
        let width = count == 1 ? totalWidth : (totalWidth - gap) / 2
        let cardHeight: CGFloat = bounds.width < 500 ? 210 : 292
        for (index, card) in visibleCards.enumerated() {
            let x = 32 + CGFloat(index) * (width + gap)
            draw(card: card, in: NSRect(x: x, y: 105, width: width, height: cardHeight))
        }
    }

    private func draw(card: CyberDashboardCard, in rect: NSRect) {
        if rect.width < 400 {
            drawCompactCard(card: card, in: rect)
            return
        }
        let accent = card.isRecommended ? NSColor.cyan : NSColor.magenta
        rounded(rect, radius: 18, fill: NSColor.black.withAlphaComponent(0.28), stroke: accent.withAlphaComponent(0.75), lineWidth: card.isRecommended ? 1.8 : 1)
        let topGlow = NSRect(x: rect.minX + 1, y: rect.minY + 1, width: rect.width - 2, height: 4)
        rounded(topGlow, radius: 2, fill: accent.withAlphaComponent(0.85), stroke: nil, lineWidth: 0)
        text(card.name.uppercased(), at: NSPoint(x: rect.minX + 22, y: rect.minY + 24), font: .systemFont(ofSize: 18, weight: .bold), color: .white)
        text(card.plan.uppercased(), at: NSPoint(x: rect.minX + 22, y: rect.minY + 51), font: .monospacedSystemFont(ofSize: 10, weight: .medium), color: accent)
        if card.isRecommended {
            let badge = NSRect(x: rect.maxX - 122, y: rect.minY + 21, width: 100, height: 24)
            rounded(badge, radius: 12, fill: NSColor.cyan.withAlphaComponent(0.15), stroke: NSColor.cyan.withAlphaComponent(0.7), lineWidth: 1)
            text("RECOMMENDED", at: NSPoint(x: badge.minX + 10, y: badge.minY + 7), font: .monospacedSystemFont(ofSize: 8, weight: .bold), color: .cyan)
        }
        drawMetric(label: card.shortLabel, remaining: card.shortRemaining, reset: card.shortReset, at: NSPoint(x: rect.minX + 22, y: rect.minY + 95), width: rect.width - 44, accent: accent)
        drawMetric(label: card.longLabel, remaining: card.longRemaining, reset: card.longReset, at: NSPoint(x: rect.minX + 22, y: rect.minY + 177), width: rect.width - 44, accent: .magenta)
        text(card.syncText, at: NSPoint(x: rect.minX + 22, y: rect.maxY - 28), font: .monospacedSystemFont(ofSize: 9, weight: .regular), color: NSColor.white.withAlphaComponent(0.42))
    }

    private func drawCompactCard(card: CyberDashboardCard, in rect: NSRect) {
        let accent = card.isRecommended ? NSColor.cyan : NSColor.magenta
        rounded(rect, radius: 16, fill: NSColor.black.withAlphaComponent(0.28), stroke: accent.withAlphaComponent(0.75), lineWidth: 1.4)
        rounded(NSRect(x: rect.minX + 1, y: rect.minY + 1, width: rect.width - 2, height: 4), radius: 2, fill: accent.withAlphaComponent(0.85), stroke: nil, lineWidth: 0)
        text(card.name.uppercased(), at: NSPoint(x: rect.minX + 18, y: rect.minY + 18), font: .systemFont(ofSize: 16, weight: .bold), color: .white)
        text(card.plan.uppercased(), at: NSPoint(x: rect.minX + 18, y: rect.minY + 42), font: .monospacedSystemFont(ofSize: 9, weight: .medium), color: accent)
        if card.isRecommended {
            let badge = NSRect(x: rect.maxX - 112, y: rect.minY + 16, width: 92, height: 22)
            rounded(badge, radius: 11, fill: NSColor.cyan.withAlphaComponent(0.15), stroke: NSColor.cyan.withAlphaComponent(0.7), lineWidth: 1)
            text("ROUTED", at: NSPoint(x: badge.minX + 22, y: badge.minY + 6), font: .monospacedSystemFont(ofSize: 8, weight: .bold), color: .cyan)
        }
        let metricY = rect.minY + 78
        let metricWidth = (rect.width - 54) / 2
        drawCompactMetric(label: card.shortLabel, remaining: card.shortRemaining, reset: card.shortReset, at: NSPoint(x: rect.minX + 18, y: metricY), width: metricWidth, accent: .cyan)
        drawCompactMetric(label: card.longLabel, remaining: card.longRemaining, reset: card.longReset, at: NSPoint(x: rect.minX + 36 + metricWidth, y: metricY), width: metricWidth, accent: .magenta)
        text(card.syncText, at: NSPoint(x: rect.minX + 18, y: rect.maxY - 22), font: .monospacedSystemFont(ofSize: 8, weight: .regular), color: NSColor.white.withAlphaComponent(0.42))
    }

    private func drawCompactMetric(label: String, remaining: Int?, reset: String, at origin: NSPoint, width: CGFloat, accent: NSColor) {
        text(label.uppercased(), at: origin, font: .monospacedSystemFont(ofSize: 8, weight: .bold), color: NSColor.white.withAlphaComponent(0.62))
        text(remaining.map { "\($0)%" } ?? "—", at: NSPoint(x: origin.x, y: origin.y + 17), font: .monospacedSystemFont(ofSize: 25, weight: .bold), color: accent)
        let track = NSRect(x: origin.x, y: origin.y + 50, width: width, height: 6)
        rounded(track, radius: 3, fill: NSColor.white.withAlphaComponent(0.11), stroke: nil, lineWidth: 0)
        if let remaining {
            rounded(NSRect(x: track.minX, y: track.minY, width: max(3, track.width * CGFloat(remaining) / 100), height: track.height), radius: 3, fill: accent, stroke: nil, lineWidth: 0)
        }
        let resetText = reset.replacingOccurrences(of: "RESET  ", with: "")
        text(resetText, at: NSPoint(x: origin.x, y: origin.y + 66), font: .monospacedSystemFont(ofSize: 8, weight: .regular), color: NSColor.white.withAlphaComponent(0.52))
    }

    private func drawMetric(label: String, remaining: Int?, reset: String, at origin: NSPoint, width: CGFloat, accent: NSColor) {
        text(label.uppercased(), at: origin, font: .monospacedSystemFont(ofSize: 10, weight: .bold), color: NSColor.white.withAlphaComponent(0.62))
        let number = remaining.map { "\($0)%" } ?? "—"
        text(number, at: NSPoint(x: origin.x, y: origin.y + 19), font: .monospacedSystemFont(ofSize: 29, weight: .bold), color: accent)
        text("AVAILABLE", at: NSPoint(x: origin.x + 74, y: origin.y + 31), font: .monospacedSystemFont(ofSize: 9, weight: .medium), color: NSColor.white.withAlphaComponent(0.46))
        let track = NSRect(x: origin.x, y: origin.y + 57, width: width, height: 8)
        rounded(track, radius: 4, fill: NSColor.white.withAlphaComponent(0.11), stroke: nil, lineWidth: 0)
        if let remaining {
            let fill = NSRect(x: track.minX, y: track.minY, width: max(4, track.width * CGFloat(remaining) / 100), height: track.height)
            rounded(fill, radius: 4, fill: accent, stroke: nil, lineWidth: 0)
        }
        text(reset, at: NSPoint(x: origin.x, y: origin.y + 71), font: .monospacedSystemFont(ofSize: 10, weight: .regular), color: NSColor.white.withAlphaComponent(0.6))
    }

    private func drawRecommendation(in bounds: NSRect) {
        let rect = NSRect(x: 32, y: bounds.height - 98, width: bounds.width - 64, height: 62)
        rounded(rect, radius: 16, fill: NSColor(red: 0.02, green: 0.22, blue: 0.26, alpha: 0.72), stroke: NSColor.cyan.withAlphaComponent(0.75), lineWidth: 1)
        text("◈  ACCOUNT ROUTING", at: NSPoint(x: rect.minX + 18, y: rect.minY + 14), font: .monospacedSystemFont(ofSize: 10, weight: .bold), color: .cyan)
        text(recommendation, at: NSPoint(x: rect.minX + 18, y: rect.minY + 33), font: .systemFont(ofSize: 13, weight: .semibold), color: .white)
        if let diagnostic {
            text(diagnostic, at: NSPoint(x: rect.maxX - 260, y: rect.minY + 14), font: .monospacedSystemFont(ofSize: 8, weight: .regular), color: NSColor.red.withAlphaComponent(0.8))
        }
    }

    private func rounded(_ rect: NSRect, radius: CGFloat, fill: NSColor, stroke: NSColor?, lineWidth: CGFloat) {
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        fill.setFill()
        path.fill()
        if let stroke {
            stroke.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
        }
    }

    private func text(_ value: String, at point: NSPoint, font: NSFont, color: NSColor) {
        value.draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
    }
}
