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
                MatchEditor { result in
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



#Preview {
    ContentView()
        .modelContainer(for: [Match.self, Player.self, SPPEvent.self], inMemory: true)
}
