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

    @State private var showingSummary = false
    @State private var pendingType: SPPEventType? = nil
    @State private var pendingCasualtyKind: CasualtyKind? = nil
    @State private var showPlayerPicker: Bool = false
    @State private var editorTarget: EditTarget? = nil

    // MARK: - Model

    private struct EditTarget: Identifiable {
        let id = UUID()
        let event: SPPEvent?
    }

    // MARK: - Body

    var body: some View {
        List {
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
                        editorTarget = EditTarget(event: event)
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
                            editorTarget = EditTarget(event: event)
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
                    editorTarget = EditTarget(event: nil)
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
        .sheet(item: $editorTarget) { target in
            EventEditor(match: match, event: target.event) { result in
                switch result {
                case .cancel:
                    break
                case .save(let updated):
                    if let existing = target.event {
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
                editorTarget = nil
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
            turn: match.currentTurnGuess,
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
