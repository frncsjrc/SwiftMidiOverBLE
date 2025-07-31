//
//  ContentView.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 25/05/2025.
//

import SwiftUI

struct PeripheralView: View {
    @Binding var midiPeripheral: MidiPeripheral

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Section(header: Text("Setup").font(.headline)) {
                    Toggle(
                        "Advertize Bluetooth MIDI",
                        isOn: $midiPeripheral.advertize
                    )
                    .onChange(of: midiPeripheral.advertize) {
                        midiPeripheral.updateAdvertising()
                    }
                    .padding()

                    Button(
                        "Sample 1",
                        systemImage: "play",
                        action: {
                            midiPeripheral.send(MidiMessage.samples1[0])
                        }
                    )

                    Button(
                        "Sample 2",
                        systemImage: "play",
                        action: {
                            midiPeripheral.send(MidiMessage.samples2[0])
                        }
                    )

                    Button(
                        "Sample 3",
                        systemImage: "play",
                        action: {
                            midiPeripheral.send(MidiMessage.samples2[1])
                        }
                    )
                }
                .padding()

                Section(header: Text("Last Incoming Messages").font(.headline))
                {
                    if midiPeripheral.subscribedCentrals.isEmpty {
                        HStack {
                            Spacer()
                            Text("No central subscribed yet.")
                                .foregroundColor(.secondary)
                                .italic()
                            Spacer()
                        }
                    } else {
                        ForEach(
                            midiPeripheral.subscribedCentrals.keys.sorted(by: {
                                $0.identifier < $1.identifier
                            }),
                            id: \.self
                        ) { central in
                            let receivedData = midiPeripheral.subscribedCentrals[central]
                            HStack {
                                Label(
                                    "\(central.identifier)",
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
                                MessageArrayView(messages: receivedData!.messages)
                            }
                        }
                    }
                }
                .padding()

            }
        }
        .padding()
        .onAppear {
            DispatchQueue.main.async {
                midiPeripheral.addMidiServiceIfNeeded()
                midiPeripheral.advertize = true
                if midiPeripheral.error != nil {
                    print(midiPeripheral.error!)
                }
            }
        }
    }
}

#Preview {
    PeripheralView(midiPeripheral: .constant(MidiPeripheral()))
}
