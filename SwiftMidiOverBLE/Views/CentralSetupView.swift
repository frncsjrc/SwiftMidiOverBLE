//
//  CentralSetupView.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 01/08/2025.
//

import SwiftUI

struct CentralSetupView: View {
    @Binding var central: Central

    var body: some View {
        Group {
            ScrollView {
                if central.remotePeripherals.isEmpty {
                    HStack {
                        Spacer()
                        Text("No peripherals found")
                            .foregroundColor(.secondary)
                            .italic()
                        Spacer()
                    }
                    .padding(.top)
                } else {
                    ForEach(
                        central.remotePeripherals.keys.sorted(),
                        id: \.self
                    ) { peripheral in
                        RemotePeripheralView(
                            central: $central,
                            identifier: peripheral
                        )
                    }
                }
            }

            VStack {
                Button(
                    "Sample 1",
                    systemImage: "play",
                    action: {
                        central.send(Message.samples1[0])
                    }
                )

                Button(
                    "Sample 2",
                    systemImage: "play",
                    action: {
                        central.send(Message.samples2[0])
                    }
                )

                Button(
                    "Sample 3",
                    systemImage: "play",
                    action: {
                        central.send(Message.samples2[1])
                    }
                )
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    @Previewable @State var central = Central()
    central.remotePeripherals = Central.remoteSamples1
    
    return CentralSetupView(central: $central)
}
