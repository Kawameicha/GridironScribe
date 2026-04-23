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

    // Players participating (both teams combined for simplicity)
    @Relationship(deleteRule: .cascade, inverse: \Player.match)
    var players: [Player]

    // Events that occurred during the match
    @Relationship(deleteRule: .cascade, inverse: \SPPEvent.match)
    var events: [SPPEvent]

    init(id: UUID = UUID(), name: String, date: Date = .now, teamA: String, teamB: String, players: [Player] = [], events: [SPPEvent] = []) {
        self.id = id
        self.name = name
        self.date = date
        self.teamA = teamA
        self.teamB = teamB
        self.players = players
        self.events = events
    }

    func teamName(for side: TeamSide) -> String { side == .home ? teamA : teamB }

    var totalSPPTeamA: Int { events.filter { $0.player.side == .home }.reduce(0) { $0 + $1.type.sppValue } }
    var totalSPPTeamB: Int { events.filter { $0.player.side == .away }.reduce(0) { $0 + $1.type.sppValue } }
}

extension Match {
    var sortedEvents: [SPPEvent] {
        events.sorted {
            if $0.turn != $1.turn {
                return $0.turn < $1.turn
            }
            if $0.timestamp != $1.timestamp {
                return $0.timestamp < $1.timestamp
            }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
}

enum TeamSide: String, Codable, CaseIterable, Identifiable {
    case home
    case away
    var id: String { rawValue }
}
