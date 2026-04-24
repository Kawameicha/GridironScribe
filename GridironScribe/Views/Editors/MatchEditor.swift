//
//  MatchEditor.swift
//  GridironScribe
//
//  Created by Christoph Freier on 23.04.26.
//

import SwiftUI

struct MatchEditor: View {
    enum EditorResult { case cancel, save(Match) }

    @Environment(\.dismiss) private var dismiss

    let match: Match?
    let onComplete: (EditorResult) -> Void

    @State private var teamA: String = ""
    @State private var teamB: String = ""
    @State private var name: String = ""
    @State private var nameWasEdited: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Teams") {
                    TextField("Home team", text: $teamA)
                    TextField("Away team", text: $teamB)
                }
                Section("Match") {
                    TextField("Match name (optional)", text: $name)
                        .onChange(of: name) { _, _ in
                            nameWasEdited = true
                        }
                }
            }
            .navigationTitle(match == nil ? "New Match" : "Edit Match")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onComplete(.cancel)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(match == nil ? "Create" : "Save") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear(perform: load)
        }
    }

    // MARK: - Helpers

    /// Auto-generates "TeamA vs TeamB" unless the user has typed a custom name.
    private var finalName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "\(teamA) vs \(teamB)" : trimmed
    }

    private var isValid: Bool {
        let a = teamA.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = teamB.trimmingCharacters(in: .whitespacesAndNewlines)
        return !a.isEmpty && !b.isEmpty && a.lowercased() != b.lowercased()
    }

    private func load() {
        guard let match else { return }
        teamA = match.teamA
        teamB = match.teamB
        // Only populate the name field if it was explicitly set by the user
        // (i.e. it differs from the auto-generated default). This way,
        // re-editing a match with an auto-name shows an empty field, not the formula.
        let autoName = "\(match.teamA) vs \(match.teamB)"
        name = match.name == autoName ? "" : match.name
    }

    // MARK: - Actions

    private func save() {
        if let existing = match {
            existing.teamA = teamA
            existing.teamB = teamB
            existing.name  = finalName
            onComplete(.save(existing))
        } else {
            let newMatch = Match(
                name: finalName,
                date: .now,
                teamA: teamA,
                teamB: teamB
            )
            for i in 1...Match.defaultRosterSize {
                newMatch.players.append(Player(number: i, side: .home, match: newMatch))
                newMatch.players.append(Player(number: i, side: .away, match: newMatch))
            }
            onComplete(.save(newMatch))
        }
        dismiss()
    }
}
