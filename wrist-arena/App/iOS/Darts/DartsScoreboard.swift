import ArenaCore
import SwiftUI
import WristKit

/// Karty graczy z wynikiem zależnym od wariantu (telefon i TV).
struct DartsScoreboard: View {
    let match: DartsMatch
    /// Większe liczby na ekran TV.
    var large = false

    var body: some View {
        HStack(spacing: large ? 16 : 8) {
            ForEach(Array(match.players.enumerated()), id: \.element.id) { index, player in
                let isCurrent = index == match.currentIndex && !match.isFinished
                VStack(spacing: 2) {
                    Text(player.name)
                        .font(large ? .title2 : .caption)
                        .lineLimit(1)
                    Text(primary(for: player, index: index))
                        .font(.system(large ? .largeTitle : .title, design: .rounded, weight: .bold).monospacedDigit())
                        .contentTransition(.numericText())
                    Text(secondary(for: player, index: index) ?? " ")
                        .font((large ? Font.body : Font.caption2).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, large ? 16 : 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isCurrent ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrent ? Color.accentColor : .clear, lineWidth: 2)
                )
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// Duża liczba: X01 = do zera, Cricket = punkty, Around the Clock = bieżący cel.
    private func primary(for player: PlayerProfile, index: Int) -> String {
        switch match.state {
        case .x01(let s):
            return "\(s.remaining[index])"
        case .cricket(let s):
            return "\(s.points[index])"
        case .aroundTheClock:
            guard let target = match.clockTarget(for: player) else { return "✓" }
            return target == 25 ? "Bull" : "\(target)"
        }
    }

    private func secondary(for player: PlayerProfile, index: Int) -> String? {
        switch match.state {
        case .x01(let s):
            return s.threeDartAverage(for: player.id).map { "śr. \(Self.format($0))" }
        case .cricket(let s):
            let closed = "\(s.closedCount(player: index))/\(CricketRules.targets.count)"
            return s.marksPerRound(player: index).map { "\(closed) · MPR \(Self.format($0))" } ?? closed
        case .aroundTheClock(let s):
            guard case .aroundTheClock(let rules) = match.game else { return nil }
            return "\(s.progress[index])/\(rules.sequence.count)"
        }
    }

    static func format(_ value: Double) -> String { StatFormat.decimal(value) }
}

/// Formatowanie liczb w statystykach (poza widokiem, więc bez izolacji do głównego aktora).
enum StatFormat {
    static func decimal(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }

    static func percent(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0)))
    }
}

/// Tabela Cricket: znaki każdego gracza na polach 20–15 i środku.
struct CricketTable: View {
    let state: CricketState
    let players: [PlayerProfile]
    var large = false

    var body: some View {
        Grid(horizontalSpacing: large ? 24 : 12, verticalSpacing: large ? 8 : 2) {
            GridRow {
                Text("")
                ForEach(players) { player in
                    Text(player.name).font(large ? .headline : .caption2).lineLimit(1)
                }
            }
            ForEach(Array(CricketRules.targets.enumerated()), id: \.offset) { target, number in
                let closedByAll = players.indices.allSatisfy { state.isClosed(player: $0, target: target) }
                GridRow {
                    Text(number == 25 ? "Bull" : "\(number)")
                        .font((large ? Font.title3 : Font.caption).weight(.semibold).monospacedDigit())
                        .gridColumnAlignment(.trailing)
                    ForEach(players.indices, id: \.self) { player in
                        MarkSymbol(marks: state.displayMarks(player: player, target: target))
                            .font(large ? .title2 : .body)
                    }
                }
                .opacity(closedByAll ? 0.3 : 1)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

/// Znak w Cricket: / (1), X (2), ⓧ (3 = zamknięte).
private struct MarkSymbol: View {
    let marks: Int

    var body: some View {
        switch marks {
        case 0: Text("·").foregroundStyle(.tertiary)
        case 1: Image(systemName: "line.diagonal")
        case 2: Image(systemName: "xmark")
        default: Image(systemName: "xmark.circle.fill").foregroundStyle(Color.accentColor)
        }
    }
}
