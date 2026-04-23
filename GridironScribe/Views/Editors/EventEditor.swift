//
//  EventEditor.swift
//  GridironScribe
//
//  Created by Christoph Freier on 23.04.26.
//

import SwiftUI

struct EventEditor: View {
    enum Result { case cancel, save(SPPEvent) }

    @Environment(\.dismiss) private var dismiss

    let match: Match
    var event: SPPEvent?
    var onComplete: (Result) -> Void

    // Editable fields
    @State private var name: String = ""
    @State private var turn: Int = 1
    @State private var type: SPPEventType = .completion
    @State private var selectedPlayer: Player
    @State private var selectedSide: TeamSide = .home

    init(match: Match, event: SPPEvent?, onComplete: @escaping (Result) -> Void) {
        self.match = match
        self.event = event
        self.onComplete = onComplete

        // Default player = first player of home team (safe fallback)
        let defaultPlayer = match.players.first!

        _selectedPlayer = State(initialValue: event?.player ?? defaultPlayer)
        _selectedSide = State(initialValue: event?.player.side ?? .home)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Team selection by side
                Picker("Team", selection: $selectedSide) {
                    Text(match.teamA).tag(TeamSide.home)
                    Text(match.teamB).tag(TeamSide.away)
                }
                // Player selection (filtered by side)
                let filteredPlayers = match.players.filter { $0.side == selectedSide }

                Picker("Player", selection: $selectedPlayer) {
                    ForEach(filteredPlayers, id: \.id) { p in
                        Text("#\(p.number)").tag(p)
                    }
                }
                // Turn
                Stepper(value: $turn, in: 1...16) {
                    HStack {
                        Text("Turn")
                        Spacer()
                        Text("\(turn)").monospacedDigit()
                    }
                }
                // Type
                Picker("Type", selection: $type) {
                    ForEach(SPPEventType.allCases) { t in
                        Text(t.rawValue.capitalized).tag(t)
                    }
                }
                // Optional note
                TextField("Note (optional)", text: $name, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }
            .navigationTitle(event == nil ? "New Event" : "Edit Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onComplete(.cancel); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let resultEvent: SPPEvent
                        if let existing = event {
                            resultEvent = existing
                        } else {
                            resultEvent = SPPEvent(name: name, turn: turn, type: type, match: match, player: selectedPlayer)
                        }
                        resultEvent.name = name
                        resultEvent.turn = turn
                        resultEvent.timestamp = .now
                        resultEvent.type = type
                        resultEvent.player = selectedPlayer
                        onComplete(.save(resultEvent))
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var isValid: Bool {
        // Turn must be within 1-16, and type must be set. Player optional.
        (1...16).contains(turn)
    }

    private func load() {
        if let e = event {
            name = e.name
            turn = e.turn
            type = e.type
            selectedPlayer = e.player
            selectedSide = e.player.side
        } else {
            name = ""
            turn = min(max(1, lastTurnGuess()), 16)
            type = .completion

            // ensure player matches selected side
            if let first = match.players.first(where: { $0.side == selectedSide }) {
                selectedPlayer = first
            }
        }
    }

    private func lastTurnGuess() -> Int {
        let lastTurn = match.events.map(\.turn).max() ?? 0
        return min(lastTurn + 1, 16)
    }
}
