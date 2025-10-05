//
//  MidiEventType.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 25/05/2025.
//

import Foundation

enum MessageType: String, CaseIterable, Identifiable, Codable {
    // channel messages
    case noteOn = "note on"
    case noteOff = "note off"
    case polyPressure = "poly pres"
    case controlChange = "CC"
    case channelPressure = "ch pres"
    case pitchBend = "bend"
    case programChange = "prog"

    // system messages
    case systemExclusive = "SysEx"
    case midiTimeCodeQuarterFrame = "MTC qtr frame"
    case songPositionPointer = "song pos"
    case songSelect = "song sel"
    case undefinedF4H = "undef 0xF4"
    case undefinedF5H = "undef 0xF5"
    case tuneRequest = "tune"
    case systemExclusiveEnd = "SysEx end"
    case timeClock = "time clock"
    case undefinedF9H = "undef 0xF9"
    case start = "start"
    case continuePlaying = "continue"
    case stop = "stop"
    case undefinedFDH = "undef 0xFD"
    case activeSensing = "sensing"
    case systemReset = "reset"

    // off-standard combinations
    case note = "note"  // combines noteOn followed by noteOff
    case bankProgramChange = "bank prog"  // combines CC0, CC32 and PC

    var id: String { rawValue }

    var capitalized: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .noteOn: return "square.and.arrow.down"
        case .noteOff: return "square.and.arrow.up"
        case .polyPressure: return "arrow.down.to.line"
        case .controlChange: return "dial.medium"
        case .channelPressure: return "arrowshape.down"
        case .pitchBend: return "lineweight"
        case .programChange: return "barcode"

        case .systemExclusive: return "exclamationmark.shield"
        case .midiTimeCodeQuarterFrame: return "music.quarternote.3"
        case .songPositionPointer: return "bookmark"
        case .songSelect: return "book"
        case .tuneRequest: return "tuningfork"
        case .systemExclusiveEnd: return "exclamationmark.octagon"
        case .timeClock: return "clock"
        case .start: return "play.fill"
        case .continuePlaying: return "forward.frame.fill"
        case .stop: return "stop.fill"
        case .systemReset: return "xmark"

        case .note: return "music.note"
        case .bankProgramChange: return "qrcode"

        default: return "exclamationmark.triangle"
        }
    }

    var status: UInt8 {
        switch self {
        case .noteOn: return 0x90
        case .noteOff: return 0x80
        case .polyPressure: return 0xA0
        case .controlChange: return 0xB0
        case .channelPressure: return 0xD0
        case .pitchBend: return 0xE0
        case .programChange: return 0xC0

        case .systemExclusive: return 0xF0
        case .midiTimeCodeQuarterFrame: return 0xF1
        case .songPositionPointer: return 0xF2
        case .songSelect: return 0xF3
        case .undefinedF4H: return 0xF4
        case .undefinedF5H: return 0xF5
        case .tuneRequest: return 0xF6
        case .systemExclusiveEnd: return 0xF7
        case .timeClock: return 0xF8
        case .undefinedF9H: return 0xF9
        case .start: return 0xFA
        case .continuePlaying: return 0xFB
        case .stop: return 0xFC
        case .undefinedFDH: return 0xFD
        case .activeSensing: return 0xFE
        case .systemReset: return 0xFF

        // Return the first status for compound message types
        case .note: return 0x90
        case .bankProgramChange: return 0xB0
        }
    }

    var dataHeaders: [String] {
        switch self {
        case .noteOn, .noteOff, .polyPressure: return ["Note", "Velocity"]
        case .controlChange: return ["Controller", "Value"]
        case .channelPressure: return ["Pressure"]
        case .pitchBend: return ["LSB", "MSB"]
        case .programChange: return ["Program"]

        case .midiTimeCodeQuarterFrame: return ["Type|Value"]
        case .songPositionPointer: return ["LSB", "MSB"]
        case .songSelect: return ["Song #"]
        case .systemExclusive: return ["Sub-ID"]

        case .note: return ["Note", "Velocity"]
        case .bankProgramChange: return ["Bank MSB", "Bank LSB", "Program"]

        default: return []
        }
    }

    static func from(_ status: UInt8) -> MessageType? {
        let channelStatus: UInt8 = status & 0xF0

        for type in MessageType.allCases {
            switch type {
            case .noteOn, .noteOff, .polyPressure, .controlChange,
                .channelPressure, .pitchBend, .programChange:
                if channelStatus == type.status {
                    return type
                }
            case .systemExclusive, .midiTimeCodeQuarterFrame,
                .songPositionPointer, .songSelect, .undefinedF4H, .undefinedF5H,
                .tuneRequest, .systemExclusiveEnd, .timeClock, .undefinedF9H,
                .start, .continuePlaying, .stop, .undefinedFDH, .activeSensing,
                .systemReset:
                if status == type.status {
                    return type
                }
            default:
                return nil
            }
        }

        return nil
    }
}
