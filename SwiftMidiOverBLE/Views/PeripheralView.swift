//
//  ContentView.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 25/05/2025.
//

import SwiftUI

struct PeripheralView: View, MessageManagerDelegate {
    @Environment(\.deviceGeometry) private var deviceGeometry
    
    @Binding var peripheral: Peripheral
    
    @State private var incomingMessages: [Message] = []

    var body: some View {
        VStack(alignment: .leading) {
            Section(header: Text("Setup").font(.headline)) {
                Toggle(
                    "Advertize Bluetooth MIDI",
                    isOn: $peripheral.advertize
                )
                .padding()

                VStack {
                    Button(
                        "Sample 1",
                        systemImage: "play",
                        action: {
                            peripheral.send(Message.samples1[0])
                        }
                    )
                    
                    Button(
                        "Sample 2",
                        systemImage: "play",
                        action: {
                            peripheral.send(Message.samples2[0])
                        }
                    )
                    
                    Button(
                        "Sample 3",
                        systemImage: "play",
                        action: {
                            peripheral.send(Message.samples2[1])
                        }
                    )
                }
                .padding()
            }

            Section(header: Text("Incoming Messages").font(.headline)) {
                MessageArrayView(messages: incomingMessages)
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                peripheral.startup()
                peripheral.advertize = true
            }
        }
    }
    
    func process(incoming messages: [Message]) {
        DispatchQueue.main.async {
            for message in messages {
                self.incomingMessages.append(message)
            }
        }
    }
}

#Preview {
    PeripheralView(peripheral: .constant(Peripheral()))
}
