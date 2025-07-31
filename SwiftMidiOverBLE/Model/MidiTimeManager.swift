//
//  MidiTimeManager.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 23/07/2025.
//

import Foundation

class MidiTimeManager {
    private let reference: UInt64 = currentTime()

    func elapsedTime(_ since: UInt64? = nil) -> UInt64 {
        return MidiTimeManager.currentTime() - (since ?? reference)
    }

    func toString(_ time: UInt64? = nil, _ since: UInt64? = nil) -> String {
        let convertedTime = (time ?? MidiTimeManager.currentTime()) - (since ?? reference)
        var processedTime = UInt64(convertedTime / 1_000_000)

        let milliseconds = processedTime % 1000
        processedTime = processedTime / 1000

        let seconds = processedTime % 60
        processedTime = processedTime / 60

        let minutes = processedTime % 60

        let hours = (processedTime / 60) % 24

        return String(
            format: "%02d:%02d:%02d.%03d",
            hours,
            minutes,
            seconds,
            milliseconds
        )
    }
    
    static let shared = MidiTimeManager()


    static func currentTime() -> UInt64 {
        clock_gettime_nsec_np(CLOCK_MONOTONIC)
    }
}
