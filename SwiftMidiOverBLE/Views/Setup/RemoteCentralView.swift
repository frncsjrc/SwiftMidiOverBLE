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
        let remoteName = RemoteManager.shared.remoteName(for: identifier, on: peripheral)
        return remoteName != Constants.unknownRemoteName ? remoteName : ""
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
                        peripheral.disconnect(identifier)
                    } else {
                        peripheral.connect(identifier)
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
