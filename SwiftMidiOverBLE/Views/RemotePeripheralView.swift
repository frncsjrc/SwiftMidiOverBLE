//
//  DiscoveredPeripheralView.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 29/07/2025.
//

import SwiftUI
import CoreBluetooth

struct RemotePeripheralView: View {
    @Binding var central: Central
    var identifier: UUID
    
    var details: RemoteDetails? {
        central.remotePeripherals[identifier]
    }
    var state: String {
        details?.state ?? .offline == .connected ? "ON" : "OFF"
    }
    var name: String {
        details?.name ?? "UNKNOWN"
    }

    var body: some View {
        HStack {
            Text(identifier.uuidString)
                .font(.system(size: 14).monospaced())
                .foregroundStyle(.secondary)

            
            Button(
                state,
                action: {
                    if state == "ON" {
                        central.disconnect(identifier)
                    } else {
                        central.connect(identifier)
                    }
                }
            )
            .font(.caption)
            .disabled(details?.state ?? .offline == .offline)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .frame(minWidth: 60)
            .tint(state == "ON" ? .green : .gray)
            .padding(.horizontal)

            Text(name)
                .font(.headline)
        }
    }
}

#Preview {
    @Previewable @State var central = Central()
    central.remotePeripherals = Central.remoteSamples1
    let identifier = Central.remoteSamples1.first!.key
    
    return RemotePeripheralView(central: $central, identifier: identifier)
}
