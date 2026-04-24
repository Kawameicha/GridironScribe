//
//  EventTypePad.swift
//  GridironScribe
//
//  Created by Christoph Freier on 23.04.26.
//

import SwiftUI

struct EventTypePad: View {
    var onSelect: (SPPEventType, CasualtyKind?) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SPPEventType.allCases) { type in
                typeButton(for: type)
            }
        }
    }

    @ViewBuilder
    private func typeButton(for type: SPPEventType) -> some View {
        if type == .casualty {
            Button(type.shortLabel) {
                onSelect(.casualty, .badlyHurt)
            }
            .buttonStyle(.bordered)
            .font(.caption)
            .contextMenu {
                ForEach(CasualtyKind.allCases) { kind in
                    Button(kind.shortLabel) {
                        onSelect(.casualty, kind)
                    }
                }
            }
        } else {
            Button(type.shortLabel) {
                onSelect(type, nil)
            }
            .buttonStyle(.bordered)
            .font(.caption)
        }
    }
}
