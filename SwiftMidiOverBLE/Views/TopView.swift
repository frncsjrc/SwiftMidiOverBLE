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

    @State private var range: MessageMask.Bounds? = (lower: 10, upper: 100)
    
    @Binding var peripheral: Peripheral
    @Binding var central: Central

    @State private var incomingMessages: [Message] = []

    var body: some View {
        Group {
            if deviceGeometry.isPortrait {
                VStack(alignment: .leading) {
//                    RangePicker(range: $range, minimumValue: 2, maximumValue: 123, allowRange: true)
//                        .font(.system(size: 12))
                    SetupView(peripheral: $peripheral, central: $central)
                    Divider()
                    OutgoingView(peripheral: $peripheral, central: $central)
                    Divider()
                    IncomingView(messages: incomingMessages)
                }
                .padding()
            } else {
                HStack(alignment: .top) {
                    VStack {
                        SetupView(peripheral: $peripheral, central: $central)
                        Divider()
                        OutgoingView(peripheral: $peripheral, central: $central)
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
    
    RemoteManager.shared.pseudos[Peripheral.remoteSamples1.first!.key] = "Test 1"
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
