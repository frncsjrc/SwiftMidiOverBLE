//
//  ContentView.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 25/05/2025.
//

import CoreBluetooth
import SwiftUI

struct CentralView: View, MessageManagerDelegate {
    @Environment(\.deviceGeometry) private var deviceGeometry

    @Binding var central: Central
    
    @State private var incomingMessages: [Message] = []

    var body: some View {
        Group {
            if deviceGeometry.isPortrait {
                VStack(alignment: .leading) {
                    Section(
                        header:
                            Text("Setup")
                            .font(.headline)
                            .padding(.bottom)
                    ) {
                        CentralSetupView(central: $central)
                    }
                    Divider()
                    Section(
                        header:
                            Text("Last Incoming Messages")
                            .font(.headline)
                            .padding(.bottom)
                    ) {
                        MessageArrayView(messages: incomingMessages)
                    }
                    
                }
                .padding()
            } else {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Section(
                            header:
                                Text("Setup")
                                .font(.headline)
                                .padding(.bottom)
                        ) {
                            VStack {
                                CentralSetupView(central: $central)
                            }
                        }
                    }
                    Divider()
                    VStack(alignment: .leading) {
                        Section(
                            header:
                                Text("Last Incoming Messages")
                                .font(.headline)
                                .padding(.bottom)
                        ) {
                            MessageArrayView(messages: incomingMessages)
                        }
                    }
                    
                }
                .padding()
            }
        }
        .onAppear {
            MessageManager.shared.delegate = self
        }
    }
    
    func process(incoming messages: [Message]) {
        DispatchQueue.main.async {
            self.incomingMessages.append(contentsOf: messages)
        }
    }
}

#Preview("portrait") {
    @Previewable @State var central = Central()
    central.remotePeripherals = Central.remoteSamples1
    
    return CentralView(central: $central)
        .environment(\.deviceGeometry, .init(size: .init(width: 1, height: 2)))
}

#Preview("landscape") {
    @Previewable @State var central = Central()
    central.remotePeripherals = Central.remoteSamples1
    
    return CentralView(central: $central)
        .environment(\.deviceGeometry, .init(size: .init(width: 2, height: 1)))
}
