//
//  MatchDetailView.swift
//  GridironScribe
//
//  Created by Christoph Freier on 23.04.26.
//

import SwiftUI
import SwiftData

struct MatchDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let match: Match

    @State private var editorMode: EditorMode = .new
    @State private var showingEditor = false
    @State private var showingSummary = false
    @State private var pendingType: SPPEventType? = nil
    @State private var pendingCasualtyKind: CasualtyKind? = nil
    @State private var showPlayerPicker: Bool = false

    // MARK: - Model

    /// Tracks whether the event sheet is creating a new event or editing an existing one.
    enum EditorMode {
        case new
        case edit(SPPEvent)
    }

    /// The current event being edited, or nil when creating a new one.
    private var editingEvent: SPPEvent? {
        if case .edit(let event) = editorMode { return event }
        return nil
    }

    /// Guess the next turn based on the highest turn already recorded, clamped to 1…16.
    /// Note: this increments from the highest existing turn, which may overshoot late in a match.
    /// Adjust the logic here if you want to track the "current" game turn separately.
    private var currentTurnGuess: Int {
        let highest = match.events.map(\.turn).max() ?? 0
        return min(max(highest, 1), 16)
    }

    // MARK: - Body

    var body: some View {
        List {
//            Section("Teams") {
//                LabeledContent("Home", value: match.teamA)
//                LabeledContent("Away", value: match.teamB)
//                LabeledContent("Date", value: match.date.formatted(date: .abbreviated, time: .shortened))
//            }

            Section("Quick Add") {
                EventTypePad { selectedType, kind in
                    pendingType = selectedType
                    pendingCasualtyKind = kind
                    withAnimation { showPlayerPicker = true }
                }

                if showPlayerPicker, let type = pendingType {
                    PlayerQuickGrid(
                        teamA: match.teamA,
                        teamB: match.teamB,
                        players: match.players
                    ) { player in
                        addQuick(type, for: player, kind: pendingCasualtyKind)
                        withAnimation {
                            showPlayerPicker = false
                            pendingType = nil
                            pendingCasualtyKind = nil
                        }
                    }
                }
            }

            Section(header: eventsHeader) {
                ForEach(match.sortedEvents) { event in
                    Button {
                        editorMode = .edit(event)
                        showingEditor = true
                    } label: {
                        eventRow(event)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            delete(event: event)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            editorMode = .edit(event)
                            showingEditor = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .navigationTitle(match.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editorMode = .new
                    showingEditor = true
                } label: {
                    Label("Add Event", systemImage: "plus")
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSummary = true
                } label: {
                    Label("Summary", systemImage: "list.bullet.rectangle")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            EventEditor(match: match, event: editingEvent) { result in
                switch result {
                case .cancel:
                    break
                case .save(let updated):
                    if let existing = editingEvent {
                        existing.name = updated.name
                        existing.turn = updated.turn
                        existing.timestamp = updated.timestamp
                        existing.type = updated.type
                        existing.player = updated.player
                    } else {
                        modelContext.insert(updated)
                        match.events.append(updated)
                    }
                }
                editorMode = .new
            }
        }
        .sheet(isPresented: $showingSummary) {
            MatchSummaryView(match: match)
        }
    }

    // MARK: - Subviews

    private var eventsHeader: some View {
        HStack {
            Text("Events (\(match.events.count))")
            Spacer()
            Text("Total SPP: \(match.totalSPP(for: .home) + match.totalSPP(for: .away))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func eventRow(_ event: SPPEvent) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(event.type.rawValue.capitalized)
                    .font(.headline)
                Spacer()
                Text("+\(event.type.sppValue) SPP")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text("Turn \(event.turn) • \(event.timestamp.formatted(date: .omitted, time: .shortened))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(event.player.displayName)
                .font(.footnote)
                .foregroundStyle(.secondary)
            if !event.name.isEmpty {
                Text(event.name)
                    .font(.footnote)
            }
        }
    }

    // MARK: - Actions

    private func addQuick(
        _ type: SPPEventType,
        for player: Player,
        kind: CasualtyKind? = nil
    ) {
        let event = SPPEvent(
            name: "",
            turn: currentTurnGuess,
            type: type,
            match: match,
            player: player,
            casualtyKind: kind
        )
        modelContext.insert(event)
        try? modelContext.save()
    }

    private func delete(event: SPPEvent) {
        if let idx = match.events.firstIndex(where: { $0.id == event.id }) {
            match.events.remove(at: idx)
        }
        modelContext.delete(event)
    }
}
