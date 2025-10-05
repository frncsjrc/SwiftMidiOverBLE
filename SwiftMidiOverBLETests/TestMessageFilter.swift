//
//  TestMessageFilter.swift
//  SwiftMidiOverBLETests
//
//  Created by François Jean Raymond CLÉMENT on 28/08/2025.
//

import Testing

@testable import SwiftMidiOverBLE

@Suite("Message Filter Tests")

struct TestMessageFilter {

    let messageSamples: [Message] = [
        Message(type: .noteOn, channel: 5, data: [17, 23]),
        Message(type: .noteOff, channel: 5, data: [17, 23]),
        Message(type: .note, channel: 5, data: [17, 23]),
        Message(type: .controlChange, channel: 5, data: [17, 23]),
        Message(type: .pitchBend, channel: 5, data: [17, 23]),
        Message(type: .polyPressure, channel: 5, data: [17, 23]),
        Message(type: .programChange, channel: 5, data: [17, 23]),
        Message(type: .bankProgramChange, channel: 5, data: [17, 23, 91]),
        Message(type: .channelPressure, channel: 5, data: [17, 23]),
        Message(type: .activeSensing, channel: 5, data: [17, 23]),
        Message(type: .continuePlaying, channel: 5, data: [17, 23]),
        Message(type: .timeClock, channel: 5, data: [17, 23]),
        Message(type: .midiTimeCodeQuarterFrame, channel: 5, data: [17, 23]),
        Message(
            type: .systemExclusive,
            channel: 5,
            data: [17, 23, 127, 33, 53, 98, 1, 45]
        ),
    ]
    
    @Test("Discard role") func testDiscardFilter() async throws {
        let filter = MessageFilter(
            role: .discard,
            masks: [
                MessageMask(type: .noteOn),
                MessageMask(type: .noteOff),
                MessageMask(type: .controlChange),
                MessageMask(type: .programChange),
            ]
        )

        for sample in messageSamples {
            let shouldMatch = [.noteOn, .noteOff, .controlChange, .programChange].contains(where: { $0 == sample.type })
            
            #expect(filter.matches(sample) == shouldMatch)
            #expect(filter.preserve(sample) != shouldMatch)
            #expect(filter.discard(sample) == shouldMatch)
        }
    }
    
    @Test("Preserve role") func testPreserveFilter() async throws {
        let filter = MessageFilter(
            role: .preserve,
            masks: [
                MessageMask(type: .noteOn),
                MessageMask(type: .noteOff),
                MessageMask(type: .controlChange),
                MessageMask(type: .programChange),
            ]
        )

        for sample in messageSamples {
            let shouldMatch = [.noteOn, .noteOff, .controlChange, .programChange].contains(where: { $0 == sample.type })
            
            #expect(filter.matches(sample) == shouldMatch)
            #expect(filter.preserve(sample) == shouldMatch)
            #expect(filter.discard(sample) != shouldMatch)
        }
    }

}
