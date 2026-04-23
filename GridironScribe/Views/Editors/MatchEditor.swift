//
//  MatchCreator.swift
//  GridironScribe
//
//  Created by Christoph Freier on 23.04.26.
//

import SwiftUI

struct MatchEditor: View {
    enum Result { case cancel, save(Match) }

    @Environment(\.dismiss) private var dismiss

    @State private var teamA: String = ""
    @State private var teamB: String = ""
    @State private var name: String = ""
    let onComplete: (Result) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Teams") {
                    TextField("Home team", text: $teamA)
                    TextField("Away team", text: $teamB)
                }
                Section("Match") {
                    TextField("Match name (optional)", text: $name)
                }
            }
            .navigationTitle("New Match")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onComplete(.cancel); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let finalName: String = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "\(teamA) vs \(teamB)" : name
                        let match = Match(name: finalName, date: .now, teamA: teamA, teamB: teamB)
                        // Auto-create 16 players per team, no events
                        for i in 1...16 {
                            match.players.append(Player(number: i, side: .home, match: match))
                        }
                        for i in 1...16 {
                            match.players.append(Player(number: i, side: .away, match: match))
                        }
                        onComplete(.save(match))
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !teamA.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !teamB.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        teamA != teamB
    }
}
