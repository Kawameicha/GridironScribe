//
//  MatchSummaryView.swift
//  GridironScribe
//
//  Created by Christoph Freier on 23.04.26.
//

import SwiftUI
import SwiftData

struct MatchSummaryView: View {
    let match: Match
    @Environment(\.dismiss) private var dismiss
    @Query private var events: [SPPEvent]

    init(match: Match) {
        self.match = match
        let matchID = match.id
        self._events = Query(
            filter: #Predicate<SPPEvent> { $0.match.id == matchID },
            sort: \.timestamp
        )
    }

    // MARK: - Model

    struct PlayerStats: Identifiable {
        let id: UUID
        let player: Player
        let isMVP: Bool
        let completions: Int
        let touchdowns: Int
        let interceptions: Int
        let badlyHurt: Int
        let seriouslyInjured: Int
        let killed: Int
        let misc: Int

        var totalSPP: Int {
            (isMVP ? SPPEventType.mvp.sppValue : 0)
            + completions    * SPPEventType.completion.sppValue
            + touchdowns     * SPPEventType.touchdown.sppValue
            + interceptions  * SPPEventType.interception.sppValue
            + (badlyHurt + seriouslyInjured + killed) * SPPEventType.casualty.sppValue
            + misc           * SPPEventType.misc.sppValue
        }
    }

    private var eventsByPlayer: [UUID: [SPPEvent]] {
        Dictionary(grouping: events) { $0.player.id }
    }

    private func stats(for player: Player) -> PlayerStats {
        let playerEvents = eventsByPlayer[player.id] ?? []
        let casualties = playerEvents.filter { $0.type == .casualty }

        return PlayerStats(
            id: player.id,
            player: player,
            isMVP: playerEvents.contains { $0.type == .mvp },
            completions: playerEvents.filter { $0.type == .completion }.count,
            touchdowns: playerEvents.filter { $0.type == .touchdown }.count,
            interceptions: playerEvents.filter { $0.type == .interception }.count,
            badlyHurt: casualties.filter { ($0.casualtyKind ?? .badlyHurt) == .badlyHurt }.count,
            seriouslyInjured: casualties.filter { $0.casualtyKind == .seriouslyInjured }.count,
            killed: casualties.filter { $0.casualtyKind == .killed }.count,
            misc: playerEvents.filter { $0.type == .misc }.count
        )
    }

    private func scoringStats(for side: TeamSide) -> [PlayerStats] {
        match.players
            .filter { $0.side == side }
            .sorted { $0.number < $1.number }
            .map(stats)
            .filter {
                $0.isMVP ||
                $0.completions > 0 ||
                $0.touchdowns > 0 ||
                $0.interceptions > 0 ||
                $0.badlyHurt > 0 ||
                $0.seriouslyInjured > 0 ||
                $0.killed > 0 ||
                $0.misc > 0
            }
    }

    private var homeStats: [PlayerStats] { scoringStats(for: .home) }
    private var awayStats:  [PlayerStats] { scoringStats(for: .away) }

    private func totals(for stats: [PlayerStats]) -> (td: Int, cas: Int) {
        (
            td:  stats.reduce(0) { $0 + $1.touchdowns },
            cas: stats.reduce(0) { $0 + $1.badlyHurt + $1.seriouslyInjured + $1.killed }
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 6) {
                        headerRow

                        if !homeStats.isEmpty {
                            teamScoreRow(for: .home, stats: homeStats)
                        }

                        if !awayStats.isEmpty {
                            teamScoreRow(for: .away, stats: awayStats)
                        }
                    }
                }
            }
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerRow: some View {
        GridRow {
            Text("")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(SPPEventType.mvp.shortLabel)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(SPPEventType.completion.shortLabel)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(SPPEventType.touchdown.shortLabel)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(SPPEventType.interception.shortLabel)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(CasualtyKind.badlyHurt.shortLabel)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(CasualtyKind.seriouslyInjured.shortLabel)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(CasualtyKind.killed.shortLabel)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(SPPEventType.misc.shortLabel)
                .frame(maxWidth: .infinity, alignment: .center)
            Text("SPP")
                .bold()
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func teamScoreRow(for side: TeamSide, stats: [PlayerStats]) -> some View {
        let t = totals(for: stats)
        GridRow {
            Text("\(match.teamName(for: side)) – \(t.td) (\(t.cas) CAS)")
                .font(.headline)
                .bold()
                .gridCellColumns(10)
                .padding(.top, 4)
        }

        playerRows(stats)
    }

    @ViewBuilder
    private func playerRows(_ stats: [PlayerStats]) -> some View {
        ForEach(stats) { s in
            GridRow {
                Text("#\(s.player.number)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(s.isMVP ? "✓" : "–")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("\(s.completions)")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("\(s.touchdowns)")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("\(s.interceptions)")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("\(s.badlyHurt)")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("\(s.seriouslyInjured)")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("\(s.killed)")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("\(s.misc)")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("\(s.totalSPP)")
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .font(.subheadline)
        }
    }
}
