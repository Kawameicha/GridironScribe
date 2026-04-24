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
                    // Reset player to first on the newly selected side to avoid desync.
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
            .onAppear(perform: load)
        }
    }

    // MARK: - Actions

    private var isValid: Bool {
        (1...16).contains(turn) && selectedPlayer != nil
    }

    private func load() {
        if let e = event {
            name = e.name
            turn = e.turn
            type = e.type
            selectedPlayer = e.player
        } else {
            name = ""
            turn = match.currentTurnGuess
            type = .completion
            selectedSide = .home
            selectedPlayer = match.players.first(where: { $0.side == .home })
        }
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
