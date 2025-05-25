//
//  MidiEventType.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 25/05/2025.
//

import Foundation

enum MidiEventType: String, CaseIterable, Identifiable, Codable {
    case noteOn = "note on"
    case noteOff = "note off"
    case note = "note"
    case polyPressure = "polyphonic pressure"
    case controlChange = "control change"
    case channelPressure = "channel pressure"
    case pitchBend = "pitch bend"
    case programChange = "program change"
    case bankProgramChange = "bank program change"

    var id: String { rawValue }

    var capitalized: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .noteOn: return "square.and.arrow.down"
        case .noteOff: return "square.and.arrow.up"
        case .note: return "music.note"
        case .polyPressure: return "arrow.down.to.line"
        case .controlChange: return "dial.medium"
        case .channelPressure: return "arrowshape.down"
        case .pitchBend: return "lineweight"
        case .programChange: return "barcode"
        case .bankProgramChange: return "qrcode"
        }
    }
    
    var dataSize: Int {
        switch self {
        case .noteOn, .noteOff: return 3
        case .note: return 3
        case .polyPressure: return 3
        case .controlChange: return 3
        case .channelPressure: return 2
        case .pitchBend: return 3
        case .programChange: return 1
        case .bankProgramChange: return 3
        }
    }
}
