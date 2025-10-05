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
        details?.name ?? Constants.unknownRemoteName
    }

    var body: some View {
        Group {
            Text(identifier.uuidString)
                .font(.system(size: 14).monospaced())
                .truncationMode(.middle)
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
                .gridColumnAlignment(.leading)
        }
        .scaledToFit()
    }
}

#Preview("Remote 1") {
    @Previewable @State var central = Central()
    central.remotePeripherals = Central.remoteSamples1
    let identifier = Central.remoteSamples1.filter { $0.value.name == "Remote 1" }.keys.first!
    
    return RemotePeripheralView(central: $central, identifier: identifier)
}

#Preview("Remote 2") {
    @Previewable @State var central = Central()
    central.remotePeripherals = Central.remoteSamples1
    let identifier = Central.remoteSamples1.filter { $0.value.name == "Remote 2" }.keys.first!
    
    return RemotePeripheralView(central: $central, identifier: identifier)
}

#Preview("Remote 3") {
    @Previewable @State var central = Central()
    central.remotePeripherals = Central.remoteSamples1
    let identifier = Central.remoteSamples1.filter { $0.value.name == "Remote 3" }.keys.first!
    
    return RemotePeripheralView(central: $central, identifier: identifier)
}
