//
//  ContentView.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 25/05/2025.
//

import CoreBluetooth
import SwiftUI

struct CentralView: View {
    @Binding var midiCentral: MidiCentral

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Section(header: Text("Setup").font(.headline)) {
                    if midiCentral.discoveredPeripherals.isEmpty {
                        Text("No peripheral found")
                    } else {
                        ForEach(
                            midiCentral.discoveredPeripherals.keys.sorted(by: {
                                $0.identifier < $1.identifier
                            }),
                            id: \.self
                        ) { peripheral in
                            let details =
                                midiCentral.discoveredPeripherals[peripheral]
                                ?? MidiDefinitions.PeerDetails(
                                    name: "UNKNOWN",
                                    connected: false
                                )
                            let identifier = peripheral.identifier
                            let connected = details.connected
                            let name = details.name ?? "UNKNOWN"
                            DiscoveredPeripheralView(
                                midiCentral: midiCentral,
                                identifier: identifier,
                                connected: connected,
                                name: name
                            )
                        }
                    }

                    Button(
                        "Sample 1",
                        systemImage: "play",
                        action: {
                            midiCentral.send(MidiMessage.samples1[0])
                        }
                    )

                    Button(
                        "Sample 2",
                        systemImage: "play",
                        action: {
                            midiCentral.send(MidiMessage.samples2[0])
                        }
                    )

                    Button(
                        "Sample 3",
                        systemImage: "play",
                        action: {
                            midiCentral.send(MidiMessage.samples2[1])
                        }
                    )
                }
                .padding()

                Section(header: Text("Last Incoming Messages").font(.headline))
                {
                    if midiCentral.connectedPeripherals.isEmpty {
                        HStack {
                            Spacer()
                            Text("No peripherals connected yet.")
                                .foregroundColor(.secondary)
                                .italic()
                            Spacer()
                        }
                    } else {
                        ForEach(
                            midiCentral.connectedPeripherals.keys.sorted(by: {
                                $0.identifier < $1.identifier
                            }),
                            id: \.self
                        ) { peripheral in
                            let receivedData = midiCentral.connectedPeripherals[
                                peripheral
                            ]
                            HStack {
                                Label(
                                    "\(peripheral.identifier)",
                                    systemImage: "pianokeys"
                                )
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            }
                            if receivedData == nil {
                                HStack {
                                    Spacer()
                                    Text("Central unsubscribed.")
                                        .foregroundColor(.secondary)
                                        .italic()
                                    Spacer()
                                }
                            } else {
                                MessageArrayView(
                                    messages: receivedData!.messages
                                )
                            }
                        }
                    }
                }
                .padding()

            }
        }
        .padding()
    }
}

#Preview {
    CentralView(midiCentral: .constant(MidiCentral()))
}
