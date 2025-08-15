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
        return remoteCentrals.first(where: { $0.key == central })?.value.name ?? "UNKNOWN"
    }
    
    func startup() {
        print("setting up peripheral")
    }

    func send(_ message: Message, to centrals: [UUID] = []) {
        print("sending \(message) to \(centrals)")
    }
}
