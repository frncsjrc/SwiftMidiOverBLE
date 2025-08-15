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

    @State private var deviceGeometry: DeviceGeometry = .empty
    @State private var peripheral: Peripheral = MidiPeripheral.shared
    @State private var central: Central = MidiCentral.shared
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
                    CentralView(central: $central)
                } else {
                    PeripheralView(peripheral: $peripheral)
                }
            }
            .environment(\.deviceGeometry, deviceGeometry)
            .updateDeviceGeometry($deviceGeometry)
            .task {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    peripheral.startup()
                    central.scan = true
                    print("startup tasks initiated")
                }
            }
        }
    }
}
