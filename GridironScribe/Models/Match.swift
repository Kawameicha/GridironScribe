//
//  Match.swift
//  GridironScribe
//
//  Created by Christoph Freier on 23.04.26.
//

import Foundation
import SwiftData

@Model
final class Match {
    var id: UUID
    var name: String
    var date: Date
    var teamA: String
    var teamB: String

    @Relationship(deleteRule: .cascade, inverse: \Player.match)
    var players: [Player]

    @Relationship(deleteRule: .cascade, inverse: \SPPEvent.match)
    var events: [SPPEvent]

    init(
        id: UUID = UUID(),
        name: String,
        date: Date = .now,
        teamA: String,
        teamB: String,
        players: [Player] = [],
        events: [SPPEvent] = []
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.teamA = teamA
        self.teamB = teamB
        self.players = players
        self.events = events
    }

    static let defaultRosterSize = 16

    func teamName(for side: TeamSide) -> String {
        side == .home ? teamA : teamB
    }

    func totalSPP(for side: TeamSide) -> Int {
        events
            .filter { $0.player.side == side }
            .reduce(0) { $0 + $1.type.sppValue }
    }

    var currentTurnGuess: Int {
        let highest = events.map(\.turn).max() ?? 0
        return min(max(highest, 1), Self.defaultRosterSize)
    }
}

extension Match {
    var sortedEvents: [SPPEvent] {
        events.sorted {
            if $0.turn != $1.turn { return $0.turn < $1.turn }
            if $0.timestamp != $1.timestamp { return $0.timestamp < $1.timestamp }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
}

enum TeamSide: String, Codable, CaseIterable, Identifiable {
    case home
    case away

    var id: String { rawValue }
}
