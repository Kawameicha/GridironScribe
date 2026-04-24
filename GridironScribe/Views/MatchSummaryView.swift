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
            + completions * SPPEventType.completion.sppValue
            + touchdowns * SPPEventType.touchdown.sppValue
            + interceptions * SPPEventType.interception.sppValue
            + (badlyHurt + seriouslyInjured + killed) * SPPEventType.casualty.sppValue
            + misc * SPPEventType.misc.sppValue
        }
    }

    // MARK: - Preprocessing

    private var eventsByPlayer: [UUID: [SPPEvent]] {
        Dictionary(grouping: events) { $0.player.id }
    }

    private func stats(for player: Player) -> PlayerStats {
        let events = eventsByPlayer[player.id] ?? []
        let casualties = events.filter { $0.type == .casualty }

        return PlayerStats(
            id: player.id,
            player: player,
            isMVP: events.contains { $0.type == .mvp },
            completions: events.filter { $0.type == .completion }.count,
            touchdowns: events.filter { $0.type == .touchdown }.count,
            interceptions: events.filter { $0.type == .interception }.count,
            badlyHurt: casualties.filter { ($0.casualtyKind ?? .badlyHurt) == .badlyHurt }.count,
            seriouslyInjured: casualties.filter { $0.casualtyKind == .seriouslyInjured }.count,
            killed: casualties.filter { $0.casualtyKind == .killed }.count,
            misc: events.filter { $0.type == .misc }.count
        )
    }

    private func activeStats(for side: TeamSide) -> [PlayerStats] {
        match.players
            .filter { $0.side == side }
            .sorted { $0.number < $1.number }
            .map(stats)
            .filter {
                $0.completions > 0 ||
                $0.touchdowns > 0 ||
                $0.interceptions > 0 ||
                $0.badlyHurt > 0 ||
                $0.seriouslyInjured > 0 ||
                $0.killed > 0 ||
                $0.misc > 0 ||
                $0.isMVP
            }
    }

    private var homeStats: [PlayerStats] { activeStats(for: .home) }
    private var awayStats: [PlayerStats] { activeStats(for: .away) }

    // MARK: - View

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {

                        headerRow

                        // Home
                        if !homeStats.isEmpty {
                            teamHeader(match.teamName(for: .home))
                            rows(homeStats)
                        }

                        // Away
                        if !awayStats.isEmpty {
                            teamHeader(match.teamName(for: .away))
                            rows(awayStats)
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

    // MARK: - Components

    private var headerRow: some View {
        GridRow {
            Text("")
            Text(SPPEventType.mvp.shortLabel)
            Text(SPPEventType.completion.shortLabel)
            Text(SPPEventType.touchdown.shortLabel)
            Text(SPPEventType.interception.shortLabel)
            Text(CasualtyKind.badlyHurt.shortLabel)
            Text(CasualtyKind.seriouslyInjured.shortLabel)
            Text(CasualtyKind.killed.shortLabel)
            Text(SPPEventType.misc.shortLabel)
            Text("SPP").bold()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func teamHeader(_ name: String) -> some View {
        GridRow {
            Text(name)
                .font(.headline)
                .gridCellColumns(10)
        }
    }

    private func rows(_ stats: [PlayerStats]) -> some View {
        ForEach(stats) { s in
            GridRow {
                Text("#\(s.player.number)")
                Text(s.isMVP ? "✓" : "")
                Text("\(s.completions)")
                Text("\(s.touchdowns)")
                Text("\(s.interceptions)")
                Text("\(s.badlyHurt)")
                Text("\(s.seriouslyInjured)")
                Text("\(s.killed)")
                Text("\(s.misc)")
                Text("\(s.totalSPP)").bold()
            }
            .font(.subheadline)
        }
    }
}
