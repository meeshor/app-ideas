import ArenaCore
import SwiftUI

/// Tarcza do rzutek rysowana w `Canvas` z tej samej geometrii co `Dartboard` (mm).
/// Nowa rzutka (`highlight`) najpierw „leci” (~0,3 s, maskuje opóźnienie zegarka), a dopiero potem
/// pojawia się na tarczy. Animacja w SwiftUI (`keyframeAnimator`) — SpriteKit nie był potrzebny.
struct DartboardView: View {
    var landings: [DartLanding] = []
    /// Wyróżniona (ostatnia) rzutka.
    var highlight: DartLanding?
    /// Pokaż punkt celowania i rozrzut (debug/kalibracja).
    var showAim = false
    /// Pola do podświetlenia (cel w Around the Clock, otwarte pola w Cricket); 25 = środek.
    var highlightedNumbers: Set<Int> = []
    var onTap: (@MainActor (BoardPoint) -> Void)?
    /// Animuj lot nowej rzutki.
    var animateFlight = true

    /// Rzutka, której lot się skończył (do tego czasu nie rysujemy jej na tarczy).
    @State private var landed: DartLanding?

    private var inFlight: DartLanding? {
        guard animateFlight, let highlight, highlight != landed else { return nil }
        return highlight
    }

    var body: some View {
        GeometryReader { geometry in
            let frame = BoardFrame(size: geometry.size)
            Canvas { context, _ in
                DartboardPainter.drawBoard(in: &context, frame: frame)
                DartboardPainter.drawHighlights(highlightedNumbers, in: &context, frame: frame)
                for landing in landings where landing != inFlight {
                    DartboardPainter.drawDart(
                        landing,
                        in: &context,
                        frame: frame,
                        highlighted: landing == highlight,
                        showAim: showAim
                    )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture().onEnded { value in
                    onTap?(frame.boardPoint(at: value.location))
                }
            )
            .overlay {
                if let flight = inFlight {
                    FlyingDart(landing: flight, frame: frame) { landed = flight }
                        .id(flight)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .sensoryFeedback(.impact(weight: .light), trigger: landed)
        .accessibilityElement()
        .accessibilityLabel("Tarcza")
        .accessibilityValue(landings.map { DartsGameModel.describe($0.hit) }.joined(separator: ", "))
    }
}

/// Rzutka w locie: z dołu ekranu łukiem do punktu trafienia, zmniejszając się (perspektywa).
private struct FlyingDart: View {
    let landing: DartLanding
    let frame: BoardFrame
    let onLanded: @MainActor () -> Void

    static let duration = 0.3

    @State private var launched = false

    private struct Flight {
        var progress = 0.0
        var scale = 3.0
    }

    var body: some View {
        let end = frame.screenPoint(landing.point)
        let start = CGPoint(x: frame.center.x, y: frame.center.y + BoardFrame.viewRadius * frame.scale * 1.4)
        let arc = BoardFrame.viewRadius * frame.scale * 0.5
        Circle()
            .fill(.yellow)
            .overlay(Circle().stroke(.black, lineWidth: 1.5))
            .frame(width: 9, height: 9)
            .keyframeAnimator(initialValue: Flight(), trigger: launched) { content, flight in
                let t = flight.progress
                content
                    .scaleEffect(flight.scale)
                    .position(
                        x: start.x + (end.x - start.x) * t,
                        y: start.y + (end.y - start.y) * t - arc * 4 * t * (1 - t)
                    )
            } keyframes: { _ in
                KeyframeTrack(\.progress) { CubicKeyframe(1, duration: Self.duration) }
                KeyframeTrack(\.scale) { CubicKeyframe(1, duration: Self.duration) }
            }
            .allowsHitTesting(false)
            .onAppear { launched = true }
            .task {
                try? await Task.sleep(for: .seconds(Self.duration))
                onLanded()
            }
    }
}

/// Przeliczenie mm na tarczy ↔ punkty ekranu.
struct BoardFrame: Sendable {
    /// Promień rysunku w mm (tarcza 170 mm + pierścień z numerami).
    static let viewRadius = 205.0

    var center: CGPoint
    var scale: Double

    init(size: CGSize) {
        center = CGPoint(x: size.width / 2, y: size.height / 2)
        scale = min(size.width, size.height) / 2 / Self.viewRadius
    }

    func screenPoint(_ point: BoardPoint) -> CGPoint {
        CGPoint(x: center.x + point.x * scale, y: center.y - point.y * scale)
    }

    /// Kąt mierzony od „w górę”, zgodnie z ruchem wskazówek zegara (jak w `Dartboard`).
    func screenPoint(radius: Double, degrees: Double) -> CGPoint {
        let radians = degrees * .pi / 180
        return screenPoint(BoardPoint(x: radius * sin(radians), y: radius * cos(radians)))
    }

    func boardPoint(at location: CGPoint) -> BoardPoint {
        BoardPoint(x: (location.x - center.x) / scale, y: (center.y - location.y) / scale)
    }
}

@MainActor
enum DartboardPainter {
    static let dark = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let light = Color(red: 0.95, green: 0.91, blue: 0.82)
    static let red = Color(red: 0.84, green: 0.15, blue: 0.24)
    static let green = Color(red: 0.11, green: 0.6, blue: 0.55)

    static func drawBoard(in context: inout GraphicsContext, frame: BoardFrame) {
        let board = Dartboard.standard
        context.fill(circle(radius: BoardFrame.viewRadius, frame: frame), with: .color(dark))

        let half = Dartboard.segmentAngle / 2
        for (index, number) in Dartboard.segmentOrder.enumerated() {
            let start = Double(index) * Dartboard.segmentAngle - half
            let end = start + Dartboard.segmentAngle
            let even = index.isMultiple(of: 2)
            let single = even ? dark : light
            let accent = even ? red : green
            let rings: [(Double, Double, Color)] = [
                (board.outerBullRadius, board.tripleInnerRadius, single),
                (board.tripleInnerRadius, board.tripleOuterRadius, accent),
                (board.tripleOuterRadius, board.doubleInnerRadius, single),
                (board.doubleInnerRadius, board.doubleOuterRadius, accent)
            ]
            for (inner, outer, color) in rings {
                context.fill(sector(inner: inner, outer: outer, from: start, to: end, frame: frame), with: .color(color))
            }
            let label = Text("\(number)")
                .font(.system(size: max(9, 15 * frame.scale * 2.2), weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            context.draw(label, at: frame.screenPoint(radius: 188, degrees: Double(index) * Dartboard.segmentAngle))
        }

        context.fill(circle(radius: board.outerBullRadius, frame: frame), with: .color(green))
        context.fill(circle(radius: board.innerBullRadius, frame: frame), with: .color(red))

        // Druty między polami (cienkie linie ułatwiają ocenę trafień).
        var wires = Path()
        for index in 0..<20 {
            let degrees = Double(index) * Dartboard.segmentAngle - half
            wires.move(to: frame.screenPoint(radius: board.outerBullRadius, degrees: degrees))
            wires.addLine(to: frame.screenPoint(radius: board.doubleOuterRadius, degrees: degrees))
        }
        for radius in [board.tripleInnerRadius, board.tripleOuterRadius, board.doubleInnerRadius, board.doubleOuterRadius] {
            wires.addPath(circle(radius: radius, frame: frame))
        }
        context.stroke(wires, with: .color(.gray.opacity(0.6)), lineWidth: 0.5)
    }

    /// Półprzezroczysta poświata na wybranych sektorach (wszystkie pierścienie) albo na środku.
    static func drawHighlights(_ numbers: Set<Int>, in context: inout GraphicsContext, frame: BoardFrame) {
        guard !numbers.isEmpty else { return }
        let board = Dartboard.standard
        let glow = GraphicsContext.Shading.color(.yellow.opacity(0.35))
        let half = Dartboard.segmentAngle / 2
        for (index, number) in Dartboard.segmentOrder.enumerated() where numbers.contains(number) {
            let start = Double(index) * Dartboard.segmentAngle - half
            let end = start + Dartboard.segmentAngle
            let path = sector(inner: board.outerBullRadius, outer: board.doubleOuterRadius, from: start, to: end, frame: frame)
            context.fill(path, with: glow)
        }
        if numbers.contains(25) {
            context.fill(circle(radius: board.outerBullRadius, frame: frame), with: glow)
        }
    }

    static func drawDart(
        _ landing: DartLanding,
        in context: inout GraphicsContext,
        frame: BoardFrame,
        highlighted: Bool,
        showAim: Bool
    ) {
        if showAim {
            let spread = circle(center: landing.aim, radius: landing.spread, frame: frame)
            context.stroke(spread, with: .color(.white.opacity(0.5)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
        let size = highlighted ? 9.0 : 6.0
        let point = frame.screenPoint(landing.point)
        let rect = CGRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size)
        context.fill(Path(ellipseIn: rect), with: .color(highlighted ? .yellow : .white))
        context.stroke(Path(ellipseIn: rect), with: .color(.black), lineWidth: 1.5)
    }

    static func circle(center: BoardPoint = BoardPoint(x: 0, y: 0), radius: Double, frame: BoardFrame) -> Path {
        let c = frame.screenPoint(center)
        let r = radius * frame.scale
        return Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
    }

    /// Wycinek pierścienia jako wielokąt (bez `addArc`, żeby nie zgadywać kierunku w odwróconym układzie).
    static func sector(inner: Double, outer: Double, from start: Double, to end: Double, frame: BoardFrame) -> Path {
        let steps = 8
        var path = Path()
        for step in 0...steps {
            let degrees = start + (end - start) * Double(step) / Double(steps)
            let point = frame.screenPoint(radius: outer, degrees: degrees)
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        for step in (0...steps).reversed() {
            let degrees = start + (end - start) * Double(step) / Double(steps)
            path.addLine(to: frame.screenPoint(radius: inner, degrees: degrees))
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    DartboardView(landings: [
        DartLanding(aim: BoardPoint(x: 0, y: 103), point: BoardPoint(x: 4, y: 101), hit: .triple(20), spread: 14),
        DartLanding(aim: BoardPoint(x: 0, y: 0), point: BoardPoint(x: -30, y: -60), hit: .single(19), spread: 14)
    ], showAim: true)
    .padding()
}
