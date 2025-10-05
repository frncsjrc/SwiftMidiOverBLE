//
//  MessageMask.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 17/08/2025.
//

import Foundation

struct MessageMask {
    typealias Bounds = (lower: UInt8?, upper: UInt8?)

    var port: Port? = nil
    var remote: [UUID]? = nil
    var type: MessageType
    var channelBounds: Bounds? = nil
    var dataBounds: [Bounds]? = nil

    func matches(_ message: Message) -> Bool {
        if let maskPort = self.port, let messagePort = message.port,
            maskPort != messagePort
        {
            return false
        }

        if let maskRemote = self.remote, let messageRemote = message.remote,
            !maskRemote.isEmpty,
            !maskRemote.contains(where: { $0 == messageRemote })
        {
            return false
        }

        if message.type != self.type {
            return false
        }

        let channelMessage = [
            MessageCategory.voiceMessage, MessageCategory.modeMessage,
        ].contains(message.category)
        if let channelBounds = self.channelBounds, channelMessage {
            if let lowerBound = channelBounds.lower,
                message.channel < lowerBound
            {
                return false
            }

            if let upperBound = channelBounds.upper,
                message.channel > upperBound
            {
                return false
            }
        }

        guard let dataBounds = self.dataBounds else {
            return true
        }

        for (index, dataBounds) in dataBounds.enumerated() {
            if index >= message.data.count {
                return false
            }

            if let lowerBound = dataBounds.lower,
                message.data[index] < lowerBound
            {
                return false
            }

            if let upperBound = dataBounds.upper,
                message.data[index] > upperBound
            {
                return false
            }
        }

        return true
    }
}
