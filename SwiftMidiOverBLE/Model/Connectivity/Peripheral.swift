//
//  MidiPeerManager.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 09/08/2025.
//

import CoreBluetooth
import Foundation

@Observable
class Peripheral: NSObject {
    var advertize: Bool = false
    var remoteCentrals: [UUID: RemoteDetails] = [:]

    func centralName(_ central: UUID) -> String {
        return remoteCentrals.first(where: { $0.key == central })?.value.name
            ?? Constants.unknownRemoteName
    }

    func startup() {
        print("setting up peripheral")
    }

    func send(_ message: Message, to centrals: [UUID] = []) {
        print("sending \(message) to \(centrals)")
    }
}

extension Peripheral {
    static let remoteSamples1: [UUID: RemoteDetails] = [
        UUID(uuidString: "3461256A-35A3-F393-E0A9-BA9456DCCA9E")!:
            RemoteDetails(name: "Remote 1", state: .connected),
        UUID(uuidString: "D6A8256A-35A3-F393-E0A9-E50E24DCCA9E")!:
            RemoteDetails(name: "Remote 2", state: .disconnected),
        UUID(uuidString: "47C8256A-35A3-F393-E0A9-BC8E24DCCA9E")!:
            RemoteDetails(
                name: "Remote 3",
                state: .offline,
                manufacturer: "Tester",
                model: "Device"
            ),
    ]
}
