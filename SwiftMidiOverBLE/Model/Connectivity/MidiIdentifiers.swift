//
//  MidiCommon.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 26/07/2025.
//

import CoreBluetooth
import Foundation

struct MidiIdentifiers {
    static let gapService = CBUUID(
        string: "1800"
    )
    
    static let midiService = CBUUID(
        string: "03B80E5A-EDE8-4B33-A751-6CE34EC4C700"
    )
    
    static let deviceNameCharacteristic = CBUUID(
        string: "2A00"
    )
    
    static let midiDataCharacteristic = CBUUID(
        string: "7772E5DB-3868-4112-A1A9-F2669D106BF3"
    )
}
