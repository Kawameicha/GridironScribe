//
//  EventTypePad.swift
//  GridironScribe
//
//  Created by Christoph Freier on 23.04.26.
//

import SwiftUI

struct EventTypePad: View {
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

extension SPPEventType {
    var shortLabel: String {
        switch self {
        case .touchdown: return "Td"
        case .casualty: return "Cas"
        case .completion: return "Cp"
        case .mvp: return "MVP"
        case .interception: return "Int"
        }
    }
}
