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
            ForEach(SPPEventType.allCases, id: \.self) { t in

                if t == .casualty {
                    Button(t.shortLabel) {
                        // Default quick action → BH
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
                    Button(t.shortLabel) {
                        onSelect(t, nil)
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }
        }
    }
}
