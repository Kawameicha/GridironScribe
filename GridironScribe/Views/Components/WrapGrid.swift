//
//  WrapGrid.swift
//  GridironScribe
//
//  Created by Christoph Freier on 23.04.26.
//

import SwiftUI

struct WrapGrid: View {
    let players: [Player]
    var onPick: (Player) -> Void

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(players.sorted(by: { $0.number < $1.number })) { p in
                Button("#\(p.number)") { onPick(p) }
                    .buttonStyle(.bordered)
                    .font(.caption)
            }
        }
    }
}
