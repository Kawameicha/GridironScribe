//
//  SPPEvent.swift
//  GridironScribe
//
//  Created by Christoph Freier on 19.04.26.
//

import Foundation
import SwiftData

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
