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
    var casualtyKindRaw: String?

    @Relationship var match: Match
    @Relationship var player: Player

    init(
        id: UUID = UUID(),
        name: String,
        timestamp: Date = .now,
        turn: Int,
        type: SPPEventType,
        match: Match,
        player: Player,
        casualtyKind: CasualtyKind? = nil
    ) {
        self.id = id
        self.name = name
        self.timestamp = timestamp
        self.turn = turn
        self.typeRaw = type.rawValue
        self.match = match
        self.player = player
        self.casualtyKindRaw = casualtyKind?.rawValue
    }

    var type: SPPEventType {
        get { SPPEventType(rawValue: typeRaw) ?? .completion }
        set { typeRaw = newValue.rawValue }
    }

    var casualtyKind: CasualtyKind? {
        get {
            guard let raw = casualtyKindRaw else { return nil }
            return CasualtyKind(rawValue: raw)
        }
        set {
            casualtyKindRaw = newValue?.rawValue
        }
    }
}

enum SPPEventType: String, Codable, CaseIterable, Identifiable {
    case touchdown, casualty, completion, mvp, interception, misc

    var id: String { rawValue }

    private var config: (spp: Int, label: String) {
        switch self {
        case .touchdown: return (3, "Td")
        case .casualty: return (2, "Cas")
        case .completion: return (1, "Cp")
        case .mvp: return (4, "MVP")
        case .interception: return (2, "Int")
        case .misc: return (1, "Misc")
        }
    }

    var sppValue: Int { config.spp }
    var shortLabel: String { config.label }
}

enum CasualtyKind: String, Codable, CaseIterable, Identifiable {
    case badlyHurt, seriouslyInjured, killed

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .badlyHurt: return "Bh"
        case .seriouslyInjured: return "Si"
        case .killed: return "Ki"
        }
    }
}
