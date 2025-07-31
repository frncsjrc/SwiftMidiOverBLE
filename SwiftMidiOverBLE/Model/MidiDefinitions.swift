//
//  MidiCommon.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 26/07/2025.
//

import CoreBluetooth
import Foundation

struct MidiDefinitions {
    struct ReceivedData {
        var pendingSystemExclusiveMessage: MidiMessage? = nil
        var messages: [MidiMessage] = []
    }
    
    struct PeerDetails {
        var name: String? = nil
        var connected: Bool = false
    }

    static let serviceUUID = CBUUID(
        string: "03B80E5A-EDE8-4B33-A751-6CE34EC4C700"
    )
    
    static let characteristicUUID = CBUUID(
        string: "7772E5DB-3868-4112-A1A9-F2669D106BF3"
    )
}
