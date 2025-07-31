//
//  SwiftMidiOverBLEApp.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 25/05/2025.
//

import SwiftData
import SwiftUI

@main
struct SwiftMidiOverBLEApp: App {
    enum OperationMode: String, CaseIterable, Identifiable {
        case central, peripheral
        var id: Self { self }
    }

    @State private var midiPeripheral: MidiPeripheral = MidiPeripheral()
    @State private var midiCentral: MidiCentral = MidiCentral()
    @State private var operationMode: OperationMode = .peripheral

    var body: some Scene {
        WindowGroup {
            HStack {
                Spacer()
                Picker("Mode", selection: $operationMode) {
                    ForEach(OperationMode.allCases) { mode in
                        Text(mode.rawValue.capitalized)
                    }
                }
                .pickerStyle(.segmented)
                Spacer()
            }
            .padding(.top)
            ZStack {
                if operationMode == .central {
                    CentralView(midiCentral: $midiCentral)
                } else {
                    PeripheralView(midiPeripheral: $midiPeripheral)
                }
            }
            .task {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    midiPeripheral.addMidiServiceIfNeeded()
                    midiCentral.startScanning()
                    print("startup tasks initiated")
                }
            }
        }
    }
}
