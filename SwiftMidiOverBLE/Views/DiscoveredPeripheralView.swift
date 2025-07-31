//
//  DiscoveredPeripheralView.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 29/07/2025.
//

import SwiftUI
import CoreBluetooth

struct DiscoveredPeripheralView: View {
    var midiCentral: MidiCentral
    var identifier: UUID
    var connected: Bool
    var name: String

    var body: some View {
        let peripheral = midiCentral.discoveredPeripherals.keys.first(where: { $0.identifier == identifier })
        let buttonLabel = connected ? "Disconnect" : "Connect"
        let buttonIcon = peripheral != nil && connected ? "lightswitch.on.fill" : "lightswitch.off.fill"

        HStack {
            Text(identifier.uuidString)
                .font(.system(size: 14).monospaced())
                .foregroundStyle(.secondary)

            
            Button(
                buttonLabel,
                systemImage: buttonIcon,
                action: {
                    guard let peripheral else {
                        return
                    }
                    if connected {
                        midiCentral.disconnect(peripheral)
                    } else {
                        midiCentral.connect(peripheral)
                    }
                }
            )
//            .disabled(peripheral == nil)
            .labelStyle(.iconOnly)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(peripheral != nil && connected ? .green : .gray)
            .padding(.horizontal)

            Text(name)
        }
        .font(.system(size: 14))
    }
}

#Preview {
    DiscoveredPeripheralView(midiCentral: MidiCentral(), identifier: UUID(), connected: true, name: "Test")
}
