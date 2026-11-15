import ArenaCore
import SwiftUI

/// Bramka 3 × 2 m z siatką, strefami, piłką i bramkarzem (telefon i TV).
struct GoalView: View {
    var attempt: HandballAttempt?
    /// Pokazuj strefy 3 × 3 (pomoc przy wyborze bramkarza).
    var showZones = true
    var onTap: (@MainActor (GoalPoint) -> Void)?

    var body: some View {
        GeometryReader { geometry in
            let frame = GoalFrame(size: geometry.size)
            Canvas { context, _ in
                GoalPainter.draw(in: &context, frame: frame, showZones: showZones)
                if let attempt {
                    GoalPainter.drawAttempt(attempt, in: &context, frame: frame)
                }
            }
            .contentShape(Rectangle())
            .gesture(SpatialTapGesture().onEnded { value in
                onTap?(frame.goalPoint(at: value.location))
            })
        }
        .aspectRatio(GoalFrame.viewWidth / GoalFrame.viewHeight, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("Bramka")
        .accessibilityValue(attempt.map { HandballGameModel.describe($0.outcome) } ?? "")
    }
}

/// Metry w płaszczyźnie bramki ↔ punkty ekranu (z marginesem wokół bramki).
struct GoalFrame: Sendable {
    static let viewWidth = 4.2
    static let viewHeight = 2.7
    let goal = HandballGoal.standard
    var origin: CGPoint
    var scale: Double

    init(size: CGSize) {
        scale = min(size.width / Self.viewWidth, size.height / Self.viewHeight)
        // Punkt (0, 0) = środek linii bramkowej na podłodze.
        origin = CGPoint(x: size.width / 2, y: size.height - 0.25 * scale)
    }

    func screen(_ point: GoalPoint) -> CGPoint {
        CGPoint(x: origin.x + point.x * scale, y: origin.y - point.y * scale)
    }

    func goalPoint(at location: CGPoint) -> GoalPoint {
        GoalPoint(x: (location.x - origin.x) / scale, y: (origin.y - location.y) / scale)
    }

    func rect(x: Double, y: Double, width: Double, height: Double) -> CGRect {
        let topLeft = screen(GoalPoint(x: x, y: y + height))
        return CGRect(x: topLeft.x, y: topLeft.y, width: width * scale, height: height * scale)
    }
}

@MainActor
enum GoalPainter {
    static func draw(in context: inout GraphicsContext, frame: GoalFrame, showZones: Bool) {
        let goal = frame.goal
        let half = goal.width / 2
        // Podłoga i linia bramkowa.
        context.fill(Path(frame.rect(x: -2.1, y: -0.25, width: 4.2, height: 0.25)), with: .color(.orange.opacity(0.35)))
        // Siatka.
        let inside = frame.rect(x: -half, y: 0, width: goal.width, height: goal.height)
        context.fill(Path(inside), with: .color(.gray.opacity(0.15)))
        var net = Path()
        var x = -half
        while x <= half {
            net.move(to: frame.screen(GoalPoint(x: x, y: 0)))
            net.addLine(to: frame.screen(GoalPoint(x: x, y: goal.height)))
            x += 0.1
        }
        var y = 0.0
        while y <= goal.height {
            net.move(to: frame.screen(GoalPoint(x: -half, y: y)))
            net.addLine(to: frame.screen(GoalPoint(x: half, y: y)))
            y += 0.1
        }
        context.stroke(net, with: .color(.gray.opacity(0.35)), lineWidth: 0.5)

        if showZones {
            var zones = Path()
            for i in 1..<3 {
                let zx = -half + Double(i) * goal.width / 3
                zones.move(to: frame.screen(GoalPoint(x: zx, y: 0)))
                zones.addLine(to: frame.screen(GoalPoint(x: zx, y: goal.height)))
                let zy = Double(i) * goal.height / 3
                zones.move(to: frame.screen(GoalPoint(x: -half, y: zy)))
                zones.addLine(to: frame.screen(GoalPoint(x: half, y: zy)))
            }
            context.stroke(zones, with: .color(.secondary), style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
        }

        // Słupki i poprzeczka w biało-czerwone pasy (co 20 cm).
        let post = goal.frame
        let pieces: [CGRect] = [
            frame.rect(x: -half - post / 2, y: 0, width: post, height: goal.height + post / 2),
            frame.rect(x: half - post / 2, y: 0, width: post, height: goal.height + post / 2),
            frame.rect(x: -half - post / 2, y: goal.height - post / 2, width: goal.width + post, height: post)
        ]
        for piece in pieces {
            context.fill(Path(piece), with: .color(.white))
        }
        var stripe = 0.0
        while stripe < goal.height {
            for side in [-half, half] {
                context.fill(Path(frame.rect(x: side - post / 2, y: stripe, width: post, height: 0.2)), with: .color(.red))
            }
            stripe += 0.4
        }
        stripe = -half
        while stripe < half {
            context.fill(Path(frame.rect(x: stripe, y: goal.height - post / 2, width: 0.2, height: post)), with: .color(.red))
            stripe += 0.4
        }
    }

    static func drawAttempt(_ attempt: HandballAttempt, in context: inout GraphicsContext, frame: GoalFrame) {
        // Bramkarz: sylwetka (elipsa) w miejscu, w które się rzucił.
        let keeper = attempt.keeperAction.position
        let body = frame.rect(x: keeper.x - 0.3, y: keeper.y - 0.55, width: 0.6, height: 1.1)
        context.fill(Path(ellipseIn: body), with: .color((attempt.keeperAction.fooledByFeint ? Color.orange : .blue).opacity(0.45)))
        context.stroke(Path(ellipseIn: body), with: .color(.blue), lineWidth: 1.5)

        // Piłka (śr. ~19 cm).
        let ball = frame.rect(x: attempt.shot.point.x - 0.1, y: attempt.shot.point.y - 0.1, width: 0.2, height: 0.2)
        let color: Color = switch attempt.outcome {
        case .goal: .green
        case .saved: .yellow
        case .post: .orange
        case .miss: .red
        }
        context.fill(Path(ellipseIn: ball), with: .color(color))
        context.stroke(Path(ellipseIn: ball), with: .color(.black), lineWidth: 1.5)
    }
}

#Preview {
    GoalView(attempt: HandballAttempt(
        shooter: UUID(),
        keeper: nil,
        feints: 1,
        shot: HandballShot(aim: GoalPoint(x: 1, y: 1.5), point: GoalPoint(x: 1.1, y: 1.6), speedKmh: 90, spread: 0.2),
        keeperAction: KeeperAction(position: GoalPoint(x: -0.8, y: 0.8), fooledByFeint: true),
        outcome: .goal,
        input: .touch
    ))
    .padding()
}
