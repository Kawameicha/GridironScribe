//
//  Models.swift
//  GridironScribe
//
//  Created by Christoph Freier on 19.04.26.
//

import Foundation
import SwiftData

enum TeamSide: String, Codable, CaseIterable, Identifiable {
    case home
    case away
    var id: String { rawValue }
}

@Model
final class Match {
    var id: UUID
    var name: String
    var date: Date
    var teamA: String
    var teamB: String

    // Players participating (both teams combined for simplicity). In future, you can split by team.
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

@Model
final class Player {
    var id: UUID
    var number: Int
    var side: TeamSide

    @Relationship var match: Match?

    init(id: UUID = UUID(), number: Int, side: TeamSide, match: Match? = nil, events: [SPPEvent] = []) {
        self.id = id
        self.number = number
        self.side = side
        self.match = match
    }

    var sppTotal: Int {
        match?.events
            .filter { $0.player == self }
            .reduce(0) { $0 + $1.type.sppValue } ?? 0
    }

    var displayName: String {
        let teamName = match?.teamName(for: side) ?? (side == .home ? "Home" : "Away")
        return "\(teamName) #\(number)"
    }
}

@Model
final class SPPEvent {
    var id: UUID
    var name: String
    var timestamp: Date
    var turn: Int
    var typeRaw: String

    @Relationship var match: Match
    @Relationship var player: Player

    init(id: UUID = UUID(), name: String, timestamp: Date = .now, turn: Int, type: SPPEventType, match: Match, player: Player) {
        self.id = id
        self.name = name
        self.timestamp = timestamp
        self.turn = turn
        self.typeRaw = type.rawValue
        self.match = match
        self.player = player
    }

    var type: SPPEventType {
        get { SPPEventType(rawValue: typeRaw) ?? .completion }
        set { typeRaw = newValue.rawValue }
    }
}

enum SPPEventType: String, Codable, CaseIterable, Identifiable {
    case touchdown
    case casualty
    case completion
    case mvp
    case interception

    var id: String { rawValue }

    var sppValue: Int {
        switch self {
        case .touchdown: return 3
        case .casualty: return 2
        case .completion: return 1
        case .mvp: return 4
        case .interception: return 2
        }
    }
}
