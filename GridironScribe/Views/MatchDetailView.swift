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

    @State private var showingEditor = false
    @State private var showingSummary = false
    @State private var editingEvent: SPPEvent? = nil
    @State private var pendingType: SPPEventType? = nil
    @State private var pendingCasualtyKind: CasualtyKind? = nil
    @State private var showPlayerPicker: Bool = false

    var body: some View {
        List {
            Section("Teams") {
                LabeledContent("Home", value: match.teamA)
                LabeledContent("Away", value: match.teamB)
                LabeledContent("Date", value: match.date.formatted(date: .abbreviated, time: .shortened))
            }
            
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
                ForEach(match.sortedEvents) { e in
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
                            Text("\(e.player.displayName)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
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
                Button {
                    addNewEvent()
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
        .sheet(isPresented: $showingSummary) {
            MatchSummaryView(match: match)
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
            Button(SPPEventType.touchdown.shortLabel) { addQuick(.touchdown, for: player) }
                .buttonStyle(.bordered)
            Button(SPPEventType.casualty.shortLabel) { addQuick(.casualty, for: player) }
                .buttonStyle(.bordered)
            Button(SPPEventType.completion.shortLabel) { addQuick(.completion, for: player) }
                .buttonStyle(.bordered)
            Button(SPPEventType.mvp.shortLabel) { addQuick(.mvp, for: player) }
                .buttonStyle(.bordered)
            Button(SPPEventType.interception.shortLabel) { addQuick(.interception, for: player) }
                .buttonStyle(.bordered)
        }
        .labelStyle(.titleOnly)
        .font(.caption)
    }

    private func addQuick(
        _ type: SPPEventType,
        for player: Player,
        kind: CasualtyKind? = nil
    ) {
        let event = SPPEvent(
            name: "",
            turn: currentTurnGuess(),
            type: type,
            match: match,
            player: player,
            casualtyKind: kind
        )
        modelContext.insert(event)
        try? modelContext.save()
    }

    private func currentTurnGuess() -> Int {
        // Guess based on highest existing turn in the match; clamp to 1...16
        let highest = match.events.map(\.turn).max() ?? 0
        return min(max(highest + 1, 1), 16)
    }
}
