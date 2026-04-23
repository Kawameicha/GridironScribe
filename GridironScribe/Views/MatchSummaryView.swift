//
//  MatchSummaryView.swift
//  GridironScribe
//
//  Created by Christoph Freier on 23.04.26.
//

import SwiftUI

struct MatchSummaryView: View {
    let match: Match

    @Environment(\.dismiss) private var dismiss

    struct PlayerStats: Identifiable {
        let id: UUID
        let player: Player
        let isMVP: Bool
        let completions: Int
        let touchdowns: Int
        let interceptions: Int
        let casualties: Int
    }

    // MARK: - Preprocessing

    private var eventsByPlayer: [UUID: [SPPEvent]] {
        Dictionary(grouping: match.events) { $0.player.id }
    }

    private func stats(for player: Player) -> PlayerStats {
        let events = eventsByPlayer[player.id] ?? []

        return PlayerStats(
            id: player.id,
            player: player,
            isMVP: events.contains { $0.type == .mvp },
            completions: events.filter { $0.type == .completion }.count,
            touchdowns: events.filter { $0.type == .touchdown }.count,
            interceptions: events.filter { $0.type == .interception }.count,
            casualties: events.filter { $0.type == .casualty }.count
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
                $0.casualties > 0 ||
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
            Text("#").bold()
            Text(SPPEventType.mvp.shortLabel)
            Text(SPPEventType.completion.shortLabel)
            Text(SPPEventType.touchdown.shortLabel)
            Text(SPPEventType.interception.shortLabel)
            Text(SPPEventType.casualty.shortLabel)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func teamHeader(_ name: String) -> some View {
        GridRow {
            Text(name)
                .font(.headline)
                .gridCellColumns(6)
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
                Text("\(s.casualties)")
            }
            .font(.subheadline)
        }
    }
}
