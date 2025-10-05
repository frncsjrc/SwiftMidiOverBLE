//
//  TestMessageMask.swift
//  SwiftMidiOverBLETests
//
//  Created by François Jean Raymond CLÉMENT on 17/08/2025.
//

import Foundation
import Testing

@testable import SwiftMidiOverBLE

@Suite("Message Mask Tests")

struct TestMessageMask {
    
    @Test("Port") func testPort() async throws {
        let mask1 = MessageMask(port: .bluetoothMidiCentral, type: .note)
        
        for sample in Message.samples1 {
            let shouldMatch = sample.type == .note
            #expect(mask1.matches(sample) == shouldMatch)
        }
        
        for sample in Message.samples2 {
            let shouldMatch = sample.port == .bluetoothMidiCentral && sample.type == .note
            #expect(mask1.matches(sample) == shouldMatch)
        }
    }
    
    @Test("Remote") func testRemote() async throws {
        let remote1 = UUID(uuidString: "F04C8475-B5A3-4E4C-A5CF-C5C0AABF6F26")!
        let remote2 = UUID(uuidString: "E8D4F8C3-E4F8-4AC9-A74E-E413E1F7C57E")!
        
        let mask1 = MessageMask(remote: [remote1, remote2], type: .note)
        let mask2 = MessageMask(remote: [remote1], type: .note)
        let mask3 = MessageMask(remote: [remote2], type: .note)
        
        for sample in Message.samples1 {
            let shouldMatch = sample.type == .note
            #expect(mask1.matches(sample) == shouldMatch)
            #expect(mask2.matches(sample) == shouldMatch)
            #expect(mask3.matches(sample) == shouldMatch)
        }
        
        for sample in Message.samples2 {
            let shouldMatch = sample.remote == remote1 && sample.type == .note
            #expect(mask1.matches(sample) == shouldMatch)
            #expect(mask2.matches(sample) == shouldMatch)
            #expect(!mask3.matches(sample))
        }
    }

    @Test("Type") func testType() async throws {
        let mask = MessageMask(type: .activeSensing)

        for sample in Message.samples1 {
            let shouldMatch = sample.type == .activeSensing
            #expect(mask.matches(sample) == shouldMatch)
        }
    }
    
    @Test("Channel") func testChannel() async throws {
        let mask1 = MessageMask(
            type: .noteOn,
            channelBounds: (lower: nil, upper: nil)
        )
        let mask2 = MessageMask(
            type: .noteOn,
            channelBounds: (lower: 12, upper: nil)
        )
        let mask3 = MessageMask(
            type: .noteOn,
            channelBounds: (lower: nil, upper: 2)
        )
        let mask4 = MessageMask(
            type: .noteOn,
            channelBounds: (lower: 2, upper: 17)
        )
        let mask5 = MessageMask(
            type: .noteOn,
            channelBounds: (lower: 5, upper: 5)
        )

        for sample in Message.samples1 {
            let shouldMatch = sample.type == .noteOn
            #expect(mask1.matches(sample) == shouldMatch)
            #expect(mask2.matches(sample) == false)
            #expect(mask3.matches(sample) == false)
            #expect(mask4.matches(sample) == shouldMatch)
            #expect(mask5.matches(sample) == shouldMatch)
        }
    }
    
    @Test("Data") func testData() async throws {
        let mask1 = MessageMask(
            type: .noteOn,
            dataBounds: [(lower: nil, upper: nil)]
        )
        let mask2 = MessageMask(
            type: .noteOn,
            dataBounds: [(lower: 57, upper: nil)]
        )
        let mask3 = MessageMask(
            type: .noteOn,
            dataBounds: [(lower: nil, upper: 2)]
        )
        let mask4 = MessageMask(
            type: .noteOn,
            dataBounds: [(lower: 2, upper: 25)]
        )
        let mask5 = MessageMask(
            type: .noteOn,
            dataBounds: [(lower: 17, upper: 17)]
        )
        let mask6 = MessageMask(
            type: .noteOn,
            dataBounds: [(lower: nil, upper: nil), (lower: 17, upper: 17)]
        )
        let mask7 = MessageMask(
            type: .noteOn,
            dataBounds: [(lower: nil, upper: nil), (lower: 23, upper: 23)]
        )
        let mask8 = MessageMask(
            type: .noteOn,
            dataBounds: [(lower: nil, upper: nil), (lower: nil, upper: nil), (lower: 23, upper: 23)]
        )

        for sample in Message.samples1 {
            let shouldMatch = sample.type == .noteOn
            #expect(mask1.matches(sample) == shouldMatch)
            #expect(mask2.matches(sample) == false)
            #expect(mask3.matches(sample) == false)
            #expect(mask4.matches(sample) == shouldMatch)
            #expect(mask5.matches(sample) == shouldMatch)
            #expect(mask6.matches(sample) == false)
            #expect(mask7.matches(sample) == shouldMatch)
            #expect(mask8.matches(sample) == false)
        }
    }

}
