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
    @State private var editingMatch: Match?
    @State private var showingNewMatch = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedMatch) {
                ForEach(matches) { match in
                    NavigationLink(value: match) {
                        VStack(alignment: .leading) {
                            Text(match.name)
                                .font(.headline)
                            Text("\(match.teamA) vs \(match.teamB) — \(match.date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(match)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            editingMatch = match
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .navigationTitle("Matches")
            .toolbar {
                ToolbarItem {
                    Button { showingNewMatch = true } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewMatch) {
                MatchEditor(match: nil) { result in
                    if case .save(let match) = result {
                        modelContext.insert(match)
                        selectedMatch = match
                    }
                }
            }
            .sheet(item: $editingMatch) { match in
                MatchEditor(match: match) { _ in }
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
}

#Preview {
    ContentView()
        .modelContainer(for: [Match.self, Player.self, SPPEvent.self], inMemory: true)
}
