//
//  MidiMessageCategory.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 24/07/2025.
//

import Foundation

enum MidiMessageCategory: String, CaseIterable, Identifiable, Codable {
    case voiceMessage = "channel voic message"
    case modeMessage = "channel mode message"
    case realTimeMessage = "system real time message"
    case commonMessage = "system common message"
    case exclusiveMessage = "system exclusive message"
    
    var id: String { rawValue }
    
    var capitalized: String { rawValue.capitalized }
}
