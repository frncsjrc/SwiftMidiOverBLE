//
//  DiscoveredPeripheralView.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 29/07/2025.
//

import SwiftUI
import CoreBluetooth

struct RemoteCentralView: View {
    @Binding var peripheral: Peripheral
    var identifier: UUID
    
    var details: RemoteDetails? {
        peripheral.remoteCentrals[identifier]
    }
    var state: String {
        details?.state ?? .offline == .connected ? "ON" : "OFF"
    }
    var name: String {
        details?.name ?? Constants.unknownRemoteName
    }

    var body: some View {
        HStack {
            Text(identifier.uuidString)
                .font(.system(size: 14).monospaced())
                .foregroundStyle(.secondary)

            
            Button(
                state,
                action: {
                    // Nothing to be done as this button is always disabled
                }
            )
            .font(.caption)
            .disabled(true)
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

#Preview("Remote 1") {
    @Previewable @State var peripheral = Peripheral()
    peripheral.remoteCentrals = Peripheral.remoteSamples1
    let identifier = Peripheral.remoteSamples1.filter { $0.value.name == "Remote 1" }.keys.first!
    
    return RemoteCentralView(peripheral: $peripheral, identifier: identifier)
}

#Preview("Remote 2") {
    @Previewable @State var peripheral = Peripheral()
    peripheral.remoteCentrals = Peripheral.remoteSamples1
    let identifier = Peripheral.remoteSamples1.filter { $0.value.name == "Remote 2" }.keys.first!
    
    return RemoteCentralView(peripheral: $peripheral, identifier: identifier)
}

#Preview("Remote 3") {
    @Previewable @State var peripheral = Peripheral()
    peripheral.remoteCentrals = Peripheral.remoteSamples1
    let identifier = Peripheral.remoteSamples1.filter { $0.value.name == "Remote 3" }.keys.first!
    
    return RemoteCentralView(peripheral: $peripheral, identifier: identifier)
}
