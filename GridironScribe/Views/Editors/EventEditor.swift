//
//  EventEditor.swift
//  GridironScribe
//
//  Created by Christoph Freier on 23.04.26.
//

import SwiftUI

struct EventEditor: View {
    enum EditorResult { case cancel, save(SPPEvent) }

    @Environment(\.dismiss) private var dismiss

    let match: Match
    var event: SPPEvent?
    var onComplete: (EditorResult) -> Void

    @State private var name: String = ""
    @State private var turn: Int = 1
    @State private var type: SPPEventType = .completion
    @State private var selectedPlayer: Player? = nil
    @State private var selectedSide: TeamSide = .home

    // MARK: - Init

    init(match: Match, event: SPPEvent?, onComplete: @escaping (EditorResult) -> Void) {
        self.match = match
        self.event = event
        self.onComplete = onComplete

        if let e = event {
            _name = State(initialValue: e.name)
            _turn = State(initialValue: e.turn)
            _type = State(initialValue: e.type)
            _selectedSide = State(initialValue: e.player.side)
            _selectedPlayer = State(initialValue: e.player)
        } else {
            let firstTurn = match.currentTurnGuess
            let firstPlayer = match.players.first(where: { $0.side == .home })
            _name = State(initialValue: "")
            _turn = State(initialValue: firstTurn)
            _type = State(initialValue: .completion)
            _selectedSide = State(initialValue: .home)
            _selectedPlayer = State(initialValue: firstPlayer)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Picker("Team", selection: $selectedSide) {
                    Text(match.teamA).tag(TeamSide.home)
                    Text(match.teamB).tag(TeamSide.away)
                }
                .onChange(of: selectedSide) { _, newSide in
                    selectedPlayer = match.players.first(where: { $0.side == newSide })
                }

                let filteredPlayers = match.players.filter { $0.side == selectedSide }
                Picker("Player", selection: $selectedPlayer) {
                    ForEach(filteredPlayers, id: \.id) { p in
                        Text("#\(p.number)").tag(Optional(p))
                    }
                }

                Stepper(value: $turn, in: 1...16) {
                    HStack {
                        Text("Turn")
                        Spacer()
                        Text("\(turn)").monospacedDigit()
                    }
                }

                Picker("Type", selection: $type) {
                    ForEach(SPPEventType.allCases) { t in
                        Text(t.rawValue.capitalized).tag(t)
                    }
                }

                TextField("Note (optional)", text: $name, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }
            .navigationTitle(event == nil ? "New Event" : "Edit Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onComplete(.cancel); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Actions

    private var isValid: Bool {
        (1...16).contains(turn) && selectedPlayer != nil
    }

    private func save() {
        guard let player = selectedPlayer else { return }

        let resultEvent: SPPEvent
        if let existing = event {
            resultEvent = existing
        } else {
            resultEvent = SPPEvent(
                name: name,
                turn: turn,
                type: type,
                match: match,
                player: player
            )
        }
        resultEvent.name = name
        resultEvent.turn = turn
        resultEvent.timestamp = .now
        resultEvent.type = type
        resultEvent.player = player

        onComplete(.save(resultEvent))
        dismiss()
    }
}
