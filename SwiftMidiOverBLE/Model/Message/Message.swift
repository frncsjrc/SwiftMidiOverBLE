//
//  MidiMessage.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 22/07/2025.
//

import Foundation
import SwiftUI

class Message {
    var port: Port?
    var remote: UUID?
    var remoteStamp: UInt16?
    var localStamp: UInt64
    var type: MessageType
    var channel: UInt8
    var data: [UInt8]

    init(
        port: Port? = nil,
        remote: UUID? = nil,
        remoteStamp: UInt16? = nil,
        localStamp: UInt64 = TimeKeeper.currentTime(),
        type: MessageType,
        channel: UInt8,
        data: [UInt8]
    ) {
        self.port = port
        self.remote = remote
        self.remoteStamp = remoteStamp
        self.localStamp = localStamp
        self.type = type
        self.channel = channel
        self.data = data
    }

    init(_ message: Message) {
        self.port = message.port
        self.remote = message.remote
        self.remoteStamp = message.remoteStamp
        self.localStamp = message.localStamp
        self.type = message.type
        self.channel = message.channel
        self.data = message.data
    }

    var category: MessageCategory {
        if type == .controlChange {
            return data[0] < 120 ? .voiceMessage : .modeMessage
        } else if type.status < 0xF0 {
            return .voiceMessage
        } else if type == .systemExclusive {
            return .exclusiveMessage
        } else {
            return type.status & 0xF8 == 0xF0
                ? .commonMessage : .realTimeMessage
        }
    }

    var status: UInt8 {
        return type.status < 0xF0 ? type.status | channel : type.status
    }

    var portIcon: some View {
        Group {
            if let port = self.port { port.icon } else { EmptyView() }
        }
    }

    var sourceName: String {
        guard let port = self.port, let source = self.remote else {
            return Constants.unknownRemoteName
        }

        switch port {
        case .bluetoothMidiPeripheral:
            return MidiPeripheral.shared.centralName(source)
        case .bluetoothMidiCentral:
            return MidiCentral.shared.peripheralName(source)
        case .localCentral:
            return "LOCAL"
        case .localPeripheral:
            return "LOCAL"
        }
    }

    var toCompactString: String {
        "\(localStampToString) [\(type)] channel:\(channel) data:\(data.map{ String(format:"%02X", $0) }.joined(separator: " "))"
    }

    var toStringNoStamp: String {
        var returnedValue: String = "[\(type.rawValue)]"
        if type.status < 0xF0 {
            returnedValue += " Channel:\(channel)"
        }

        if type == .systemExclusive {
            returnedValue +=
                ", Data=\(data.map{ String(format:"%02X", $0) }.joined(separator: " "))"
        } else {
            for dataIndex in data.indices {
                if dataIndex < type.dataHeaders.count {
                    returnedValue +=
                        ", \(type.dataHeaders[dataIndex].capitalized)=\(data[dataIndex])"
                }
            }
            if data.count > type.dataHeaders.count {
                returnedValue +=
                    ", Extra data=\(data[type.dataHeaders.count...])"
            }
        }
        return returnedValue
    }

    var toStringWithLocalStamp: String {
        "\(localStampToString) \(toStringNoStamp)"
    }

    var toStringWithSourceNameAndLocalStamp: String {
        return "\(sourceName) - \(localStampToString) \(toStringNoStamp)"
    }

    var toStringWithSourceStamp: String {
        "\(remoteStamp ?? 0) \(toStringNoStamp)"
    }

    private var localStampToString: String {
        return TimeKeeper.shared.toString(localStamp, 0)
    }
}

extension Message {
    static let BankMask: UInt8 = 0xDF
    static let BankMSB: UInt8 = 0x00
    static let BankLSB: UInt8 = 0x20
}

extension Message {
    static let samples1: [Message] = [
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

    static let samples2: [Message] = [
        Message(
            port: .bluetoothMidiCentral,
            remote: UUID(uuidString: "F04C8475-B5A3-4E4C-A5CF-C5C0AABF6F26"),
            remoteStamp: 7,
            localStamp: 19,
            type: .note,
            channel: 0,
            data: [60, 100]
        ),
        Message(
            port: .bluetoothMidiPeripheral,
            remote: UUID(uuidString: "E8D4F8C3-E4F8-4AC9-A74E-E413E1F7C57E"),
            remoteStamp: 16,
            localStamp: 53,
            type: .bankProgramChange,
            channel: 0,
            data: [1, 3, 27]
        ),
    ]
}
