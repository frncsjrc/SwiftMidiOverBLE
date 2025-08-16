//
//  Central.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 09/08/2025.
//

import CoreBluetooth
import Foundation

@Observable
class Central: NSObject {
    var scan: Bool = false
    var remotePeripherals: [UUID: RemoteDetails] = [:]

    func peripheralName(_ peripheral: UUID) -> String {
        return remotePeripherals.first(where: { $0.key == peripheral })?.value
            .name ?? Constants.unknownRemoteName
    }

    func connect(_ peripheral: UUID) {
        print("connecting to \(peripheralName(peripheral))")
        remotePeripherals[peripheral]?.state = .connected
    }

    func disconnect(_ peripheral: UUID) {
        print("disconnecting from \(peripheralName(peripheral))")
        remotePeripherals[peripheral]?.state = .disconnected
    }

    func send(_ message: Message, to peripherals: [UUID] = []) {
        print("sending \(message) to \(peripherals)")
    }
}

extension Central {
    static let remoteSamples1: [UUID: RemoteDetails] = [
        UUID(uuidString: "E621E40E-B5A3-F393-E0A9-E50E24DCCA9E")!:
            RemoteDetails(name: "Remote 1", state: .connected),
        UUID(uuidString: "D4B4F4A6-B5A3-F393-E0A9-E505F32CCA9E")!:
            RemoteDetails(name: "Remote 2", state: .disconnected),
        UUID(uuidString: "47C8256A-35A3-F393-E0A9-E50E24DCCA9E")!:
            RemoteDetails(name: "Remote 3", state: .offline, manufacturer: "Tester", model: "Device"),
    ]
}
