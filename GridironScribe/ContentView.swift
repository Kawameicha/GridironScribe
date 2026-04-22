//
//  ContentView.swift
//  GridironScribe
//
//  Created by Christoph Freier on 19.04.26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Match.date, order: .reverse) private var matches: [Match]

    @State private var selectedMatch: Match?
    @State private var showingNewMatch = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedMatch) {
                ForEach(matches) { match in
                    NavigationLink(value: match) {
                        VStack(alignment: .leading) {
                            Text(match.name).font(.headline)
                            Text("\(match.teamA) vs \(match.teamB) — \(match.date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteMatches)
            }
            .navigationTitle("Matches")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
                ToolbarItem { Button(action: { showingNewMatch = true }) { Label("Add", systemImage: "plus") } }
            }
            .sheet(isPresented: $showingNewMatch) {
                MatchCreator { result in
                    switch result {
                    case .cancel:
                        break
                    case .save(let match):
                        modelContext.insert(match)
                        selectedMatch = match
                    }
                }
            }
        } detail: {
            if let match = selectedMatch {
                MatchDetailView(match: match)
            } else {
                Text("Select or add a match")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func deleteMatches(offsets: IndexSet) {
        withAnimation {
            for index in offsets { modelContext.delete(matches[index]) }
        }
    }
}

// Simple detail to inspect and manage events
struct MatchDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State var match: Match

    @State private var showingEditor = false
    @State private var editingEvent: SPPEvent? = nil
    @State private var pendingType: SPPEventType? = nil
    @State private var showPlayerPicker: Bool = false

    var body: some View {
        List {
            Section("Teams") {
                LabeledContent("Home", value: match.teamA)
                LabeledContent("Away", value: match.teamB)
                LabeledContent("Date", value: match.date.formatted(date: .abbreviated, time: .shortened))
            }
            
            Section("Quick Add") {
                EventTypePad { selected in
                    pendingType = selected
                    withAnimation { showPlayerPicker = true }
                }
                if showPlayerPicker, let type = pendingType {
                    PlayerQuickGrid(teamA: match.teamA, teamB: match.teamB, players: match.players) { player in
                        addQuick(type, for: player)
                        withAnimation {
                            showPlayerPicker = false
                            pendingType = nil
                        }
                    }
                }
            }

            Section(header: eventsHeader) {
                ForEach(match.events) { e in
                    Button {
                        editingEvent = e
                        showingEditor = true
                    } label: {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(e.type.rawValue.capitalized)
                                    .font(.headline)
                                Spacer()
                                Text("+\(e.type.sppValue) SPP")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Text("Turn \(e.turn) • \(e.timestamp.formatted(date: .omitted, time: .shortened))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if let player = e.player {
                                Text("\(player.displayName)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            if !e.name.isEmpty {
                                Text(e.name)
                                    .font(.footnote)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { delete(event: e) } label: { Label("Delete", systemImage: "trash") }
                        Button { editingEvent = e; showingEditor = true } label: { Label("Edit", systemImage: "pencil") }
                            .tint(.blue)
                    }
                }
            }
        }
        .navigationTitle(match.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { addNewEvent() } label: { Label("Add Event", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showingEditor) {
            EventEditor(match: match, event: editingEvent) { result in
                switch result {
                case .cancel:
                    break
                case .save(let updated):
                    if let existing = editingEvent {
                        // Update existing
                        existing.name = updated.name
                        existing.turn = updated.turn
                        existing.timestamp = updated.timestamp
                        existing.type = updated.type
                        existing.player = updated.player
                    } else {
                        // Insert new, already linked in editor
                        modelContext.insert(updated)
                        match.events.append(updated)
                    }
                }
                editingEvent = nil
            }
        }
    }

    private var eventsHeader: some View {
        HStack {
            Text("Events (\(match.events.count))")
            Spacer()
            Text("Total SPP: \(match.totalSPPTeamA + match.totalSPPTeamB)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func addNewEvent() {
        editingEvent = nil
        showingEditor = true
    }

    private func delete(event: SPPEvent) {
        if let idx = match.events.firstIndex(where: { $0.id == event.id }) {
            match.events.remove(at: idx)
        }
        modelContext.delete(event)
    }

    @ViewBuilder
    private func quickButtons(for player: Player) -> some View {
        HStack(spacing: 6) {
            Button("+TD") { addQuick(.touchdown, for: player) }
                .buttonStyle(.bordered)
            Button("+CAS") { addQuick(.casualty, for: player) }
                .buttonStyle(.bordered)
            Button("+COMP") { addQuick(.completion, for: player) }
                .buttonStyle(.bordered)
            Button("+MVP") { addQuick(.mvp, for: player) }
                .buttonStyle(.bordered)
            Button("+INT") { addQuick(.interception, for: player) }
                .buttonStyle(.bordered)
        }
        .labelStyle(.titleOnly)
        .font(.caption)
    }

    private func addQuick(_ type: SPPEventType, for player: Player) {
        let event = SPPEvent(
            name: "",
            turn: currentTurnGuess(),
            type: type,
            match: match,
            player: player
        )
        modelContext.insert(event)
        match.events.append(event)
    }

    private func currentTurnGuess() -> Int {
        // Guess based on highest existing turn in the match; clamp to 1...16
        let highest = match.events.map(\.turn).max() ?? 0
        return min(max(highest + 1, 1), 16)
    }
}

fileprivate struct EventTypePad: View {
    var onSelect: (SPPEventType) -> Void
    var body: some View {
        HStack(spacing: 8) {
            ForEach(SPPEventType.allCases, id: \.self) { t in
                Button(t.shortLabel) { onSelect(t) }
                    .buttonStyle(.bordered)
                    .font(.caption)
            }
        }
    }
}

fileprivate struct PlayerQuickGrid: View {
    let teamA: String
    let teamB: String
    let players: [Player]
    var onPick: (Player) -> Void

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 8)]

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading) {
                Text(teamA).font(.headline)
                WrapGrid(players: players.filter { $0.team == teamA }, onPick: onPick)
            }
            VStack(alignment: .leading) {
                Text(teamB).font(.headline)
                WrapGrid(players: players.filter { $0.team == teamB }, onPick: onPick)
            }
        }
    }
}

fileprivate struct WrapGrid: View {
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

fileprivate extension SPPEventType {
    var shortLabel: String {
        switch self {
        case .touchdown: return "TD"
        case .casualty: return "CAS"
        case .completion: return "COMP"
        case .mvp: return "MVP"
        case .interception: return "INT"
        }
    }
}

// MARK: - Event Editor
fileprivate struct EventEditor: View {
    enum Result { case cancel, save(SPPEvent) }

    @Environment(\.dismiss) private var dismiss

    let match: Match
    var event: SPPEvent?
    var onComplete: (Result) -> Void

    // Editable fields
    @State private var name: String = ""
    @State private var turn: Int = 1
    @State private var type: SPPEventType = .completion
    @State private var selectedPlayer: Player? = nil
    @State private var selectedTeam: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // Team selection
                Picker("Team", selection: $selectedTeam) {
                    Text(match.teamA).tag(match.teamA)
                    Text(match.teamB).tag(match.teamB)
                }
                // Player selection (filtered by team)
                Picker("Player", selection: Binding(get: { selectedPlayer?.id }, set: { id in
                    selectedPlayer = match.players.first(where: { $0.id == id })
                })) {
                    ForEach(match.players.filter { $0.team == selectedTeam }) { p in
                        Text("#\(p.number)").tag(Optional.some(p.id))
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
            selectedTeam = e.player?.team ?? match.teamA
        } else {
            // Defaults for new event
            name = ""
            turn = min(max(1, lastTurnGuess()), 16)
            type = .completion
            selectedPlayer = nil
            selectedTeam = match.teamA
        }
    }

    private func lastTurnGuess() -> Int {
        let lastTurn = match.events.map(\.turn).max() ?? 0
        return min(lastTurn + 1, 16)
    }
}

fileprivate struct MatchCreator: View {
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
                            match.players.append(Player(number: i, team: teamA, match: match))
                        }
                        for i in 1...16 {
                            match.players.append(Player(number: i, team: teamB, match: match))
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

#Preview {
    ContentView()
        .modelContainer(for: [Match.self, Player.self, SPPEvent.self], inMemory: true)
}
