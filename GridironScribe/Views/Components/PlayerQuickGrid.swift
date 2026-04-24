//
//  PlayerQuickGrid.swift
//  GridironScribe
//
//  Created by Christoph Freier on 23.04.26.
//

import SwiftUI

struct PlayerQuickGrid: View {
    let teamA: String
    let teamB: String
    let players: [Player]
    var onPick: (Player) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            teamColumn(
                name: teamA,
                players: players.filter { $0.side == .home }
            )
            teamColumn(
                name: teamB,
                players: players.filter { $0.side == .away }
            )
        }
    }

    private func teamColumn(name: String, players: [Player]) -> some View {
        VStack(alignment: .leading) {
            Text(name).font(.headline)
            WrapGrid(players: players, onPick: onPick)
        }
    }
}
