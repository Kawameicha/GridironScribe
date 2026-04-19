//
//  Models.swift
//  GridironScribe
//
//  Created by Christoph Freier on 19.04.26.
//

import Foundation
import SwiftData

@Model
final class Match {
    @Attribute(.unique) var id: UUID
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

    // Derived stats
    var totalSPPTeamA: Int { totalSPP(forTeamNamed: teamA) }
    var totalSPPTeamB: Int { totalSPP(forTeamNamed: teamB) }

    func totalSPP(forTeamNamed team: String) -> Int {
        events.filter { $0.player?.team == team }.reduce(0) { $0 + ($1.type.sppValue) }
    }
}

@Model
final class Player {
    @Attribute(.unique) var id: UUID
    var name: String
    var number: Int
    var team: String // Store the team name to associate with teamA/teamB

    @Relationship var match: Match?

    // Convenience aggregation
    @Relationship(deleteRule: .cascade, inverse: \SPPEvent.player)
    var events: [SPPEvent]

    init(id: UUID = UUID(), name: String, number: Int, team: String, match: Match? = nil, events: [SPPEvent] = []) {
        self.id = id
        self.name = name
        self.number = number
        self.team = team
        self.match = match
        self.events = events
    }

    var sppTotal: Int { events.reduce(0) { $0 + $1.type.sppValue } }
}

@Model
final class SPPEvent {
    @Attribute(.unique) var id: UUID
    var name: String
    var timestamp: Date
    var turn: Int
    var typeRaw: String

    @Relationship var match: Match?
    @Relationship var player: Player?

    init(id: UUID = UUID(), name: String, timestamp: Date = .now, turn: Int, type: SPPEventType, match: Match? = nil, player: Player? = nil) {
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

// MARK: - Sample Data and Factories
extension Match {
    static func makeSample() -> Match {
        let match = Match(name: "League Round 1", date: .now, teamA: "Orc Smashers", teamB: "Elf Dancers")
        // 11 players per team minimal roster
        for i in 1...11 {
            let p = Player(name: "Orc #\(i)", number: i, team: match.teamA, match: match)
            match.players.append(p)
        }
        for i in 1...11 {
            let p = Player(name: "Elf #\(i)", number: i, team: match.teamB, match: match)
            match.players.append(p)
        }
        // A couple of events
        if let scorer = match.players.first(where: { $0.team == match.teamA && $0.number == 4 }) {
            match.events.append(SPPEvent(name: "TD by #\(scorer.number)", turn: 3, type: .touchdown, match: match, player: scorer))
        }
        if let mvp = match.players.first(where: { $0.team == match.teamB && $0.number == 7 }) {
            match.events.append(SPPEvent(name: "MVP #\(mvp.number)", turn: 16, type: .mvp, match: match, player: mvp))
        }
        return match
    }
}
