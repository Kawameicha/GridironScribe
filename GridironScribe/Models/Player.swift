//
//  Player.swift
//  GridironScribe
//
//  Created by Christoph Freier on 23.04.26.
//

import Foundation
import SwiftData

@Model
final class Player {
    var id: UUID
    var number: Int
    var side: TeamSide

    @Relationship var match: Match?

    init(
        id: UUID = UUID(),
        number: Int,
        side: TeamSide,
        match: Match? = nil
    ) {
        self.id = id
        self.number = number
        self.side = side
        self.match = match
    }

    var sppTotal: Int {
        match?.events
            .filter { $0.player.id == self.id }
            .reduce(0) { $0 + $1.type.sppValue } ?? 0
    }

    var displayName: String {
        let teamName = match?.teamName(for: side) ?? (side == .home ? "Home" : "Away")
        return "\(teamName) #\(number)"
    }
}
