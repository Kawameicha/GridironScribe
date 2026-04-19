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
                ToolbarItem { Button(action: addSampleMatch) { Label("Add", systemImage: "plus") } }
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

    private func addSampleMatch() {
        withAnimation {
            let match = Match.makeSample()
            modelContext.insert(match)
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

    var body: some View {
        List {
            Section("Teams") {
                LabeledContent("Home", value: match.teamA)
                LabeledContent("Away", value: match.teamB)
                LabeledContent("Date", value: match.date.formatted(date: .abbreviated, time: .shortened))
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
                                Text("#\(player.number) \(player.name) — \(player.team)")
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
    @State private var timestamp: Date = .now
    @State private var turn: Int = 1
    @State private var type: SPPEventType = .completion
    @State private var selectedPlayer: Player? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Optional note", text: $name)
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
                    DatePicker("Time", selection: $timestamp, displayedComponents: [.hourAndMinute])
                }

                Section("Player") {
                    Picker("Player", selection: Binding(get: { selectedPlayer?.id }, set: { id in
                        selectedPlayer = match.players.first(where: { $0.id == id })
                    })) {
                        Text("None").tag(Optional<UUID>.none)
                        ForEach(match.players) { p in
                            Text("#\(p.number) \(p.name) — \(p.team)").tag(Optional.some(p.id))
                        }
                    }
                }
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
                        resultEvent.timestamp = timestamp
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
            timestamp = e.timestamp
            turn = e.turn
            type = e.type
            selectedPlayer = e.player
        } else {
            // Defaults for new event
            name = ""
            timestamp = .now
            turn = min(max(1, lastTurnGuess()), 16)
            type = .completion
            selectedPlayer = nil
        }
    }

    private func lastTurnGuess() -> Int {
        let lastTurn = match.events.map(\.turn).max() ?? 0
        return min(lastTurn + 1, 16)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Match.self, Player.self, SPPEvent.self], inMemory: true)
}
