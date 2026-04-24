//
//  GridironScribeSchema.swift
//  GridironScribe
//
//  Created by Christoph Freier on 24.04.26.
//

import SwiftData

// MARK: - Schema Versions

/// V1 — initial schema.
/// Contains: Match, Player, SPPEvent.
/// SPPEventType and CasualtyKind are stored as raw String values for stability.
enum GridironScribeSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Match.self, Player.self, SPPEvent.self]
    }
}

// MARK: - Migration Plan

/// Add a new `VersionedSchema` enum (V2, V3, …) for each breaking schema change,
/// then append a `MigrationStage` here to carry data forward.
///
/// Lightweight migration — safe for:
///   • Adding an optional property
///   • Adding a property with a default value
///   • Renaming a property (set renamingIdentifier on the old name)
///
/// Custom migration — required for:
///   • Splitting or merging models
///   • Populating a new non-optional property from existing data
///   • Any transformation that lightweight cannot express
///
/// Example of a future lightweight stage:
/// ```swift
/// .lightweight(
///     fromVersion: GridironScribeSchemaV1.self,
///     toVersion:   GridironScribeSchemaV2.self
/// )
/// ```
enum GridironScribeMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [GridironScribeSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        // No migrations yet — add stages here as the schema evolves.
        []
    }
}
