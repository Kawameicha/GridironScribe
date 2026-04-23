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

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 8)]

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading) {
                Text(teamA).font(.headline)
                WrapGrid(players: players.filter { $0.side == .home }, onPick: onPick)
            }
            VStack(alignment: .leading) {
                Text(teamB).font(.headline)
                WrapGrid(players: players.filter { $0.side == .away }, onPick: onPick)
            }
        }
    }
}
