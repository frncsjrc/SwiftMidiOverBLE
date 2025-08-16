//
//  ContentView.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 25/05/2025.
//

import CoreBluetooth
import SwiftUI

struct TopView: View, MessageManagerDelegate {
    @Environment(\.deviceGeometry) private var deviceGeometry

    @Binding var peripheral: Peripheral
    @Binding var central: Central

    @State private var incomingMessages: [Message] = []

    var body: some View {
        Group {
            if deviceGeometry.isPortrait {
                VStack(alignment: .leading) {
                    SetupView(peripheral: $peripheral, central: $central)
                    Divider()
                    IncomingView(messages: incomingMessages)
                }
                .padding()
            } else {
                HStack(alignment: .top) {
                    VStack {
                        SetupView(peripheral: $peripheral, central: $central)
                    }
                    Divider()
                    VStack {
                        IncomingView(messages: incomingMessages)
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
    @Previewable @State var peripheral = Peripheral()
    @Previewable @State var central = Central()

    peripheral.remoteCentrals = Peripheral.remoteSamples1
    central.remotePeripherals = Central.remoteSamples1

    return TopView(peripheral: $peripheral, central: $central)
        .environment(\.deviceGeometry, .init(size: .init(width: 1, height: 2)))
}

#Preview("landscape") {
    @Previewable @State var peripheral = Peripheral()
    @Previewable @State var central = Central()

    peripheral.remoteCentrals = Peripheral.remoteSamples1
    central.remotePeripherals = Central.remoteSamples1

    return TopView(peripheral: $peripheral, central: $central)
        .environment(\.deviceGeometry, .init(size: .init(width: 2, height: 1)))
}
