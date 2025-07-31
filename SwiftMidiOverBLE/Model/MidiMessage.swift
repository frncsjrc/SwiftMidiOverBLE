//
//  MidiMessage.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 22/07/2025.
//

import Foundation

class MidiMessage {
    var localStamp: UInt64
    var sourceStamp: UInt16
    var type: MidiMessageType
    var channel: UInt8
    var data: [UInt8]

    init(
        localStamp: UInt64 = MidiTimeManager.currentTime(),
        sourceStamp: UInt16,
        type: MidiMessageType,
        channel: UInt8,
        data: [UInt8]
    ) {
        self.localStamp = localStamp
        self.sourceStamp = sourceStamp
        self.type = type
        self.channel = channel
        self.data = data
    }

    var status: UInt8 {
        return type.status < 0xF0 ? type.status | channel : type.status
    }

    var toCompactString: String {
        "\(localStampToString) \(sourceStamp) [\(type)] channel:\(channel) data:\(data.map{ String(format:"%02X", $0) }.joined(separator: " "))"
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

    var toStringWithSourceStamp: String {
        "\(sourceStamp) \(toStringNoStamp)"
    }

    var toStringWithLocalStamp: String {
        "\(localStampToString) \(toStringNoStamp)"
    }

    var category: MidiMessageCategory {
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

    private var localStampToString: String {
        return MidiTimeManager.shared.toString(localStamp, 0)
    }
}

extension MidiMessage {
    func encodePackets(_ timeManager: MidiTimeManager, _ packetSize: Int)
        -> [Data]
    {
        var encodedPackets: [Data] = []

        var timeStamp = timeManager.elapsedTime() & 0x1FFF
        var timeStampMSB: UInt8 = 0x80 | UInt8(timeStamp >> 7)
        var timeStampLSB: UInt8 = 0x80 | UInt8(timeStamp & 0x7F)
        let status = status

        var encodedPacket = Data()
        encodedPacket.append(timeStampMSB)
        encodedPacket.append(timeStampLSB)
        encodedPacket.append(status)

        if type == .systemExclusive {
            let maxContinuousDataSize = packetSize - 5
            let maxSplitDataSize = packetSize - 3

            var startIndex: Int = 0
            var endIndex: Int =
                data.count <= maxContinuousDataSize
                ? data.count : maxSplitDataSize

            while endIndex < data.count {
                encodedPacket.append(contentsOf: data[startIndex..<endIndex])

                if endIndex == data.count {
                    encodedPacket.append(timeStampLSB)
                    encodedPacket.append(
                        MidiMessageType.systemExclusiveEnd.status
                    )
                }

                encodedPackets.append(encodedPacket)

                timeStamp = timeManager.elapsedTime() & 0x1FFF
                timeStampMSB = 0x80 | UInt8(timeStamp >> 7)
                timeStampLSB = 0x80 | UInt8(timeStamp & 0x7F)

                startIndex = endIndex
                endIndex = min(data.count, endIndex + maxSplitDataSize)

                encodedPacket.removeAll(keepingCapacity: true)
                encodedPacket.append(timeStampMSB)
            }
        } else if type == .note {
            data.forEach { encodedPacket.append($0) }
            encodedPacket.append(timeStampLSB)
            encodedPacket.append(MidiMessageType.noteOff.status | channel)
            data.forEach { encodedPacket.append($0) }

            encodedPackets.append(encodedPacket)
        } else if type == .bankProgramChange {
            encodedPacket.append(MidiMessage.BankMSB)
            encodedPacket.append(data.count >= 1 ? data[0] : 0)
            encodedPacket.append(MidiMessage.BankLSB)
            encodedPacket.append(data.count >= 2 ? data[1] : 0)
            encodedPacket.append(timeStampLSB)
            encodedPacket.append(MidiMessageType.programChange.status | channel)
            encodedPacket.append(data.count >= 3 ? data[2] : 0)

            encodedPackets.append(encodedPacket)
        } else {
            data.forEach { encodedPacket.append($0) }

            encodedPackets.append(encodedPacket)
        }

        return encodedPackets
    }

    static func decodePacket(
        _ packet: Data,
        _ pendingSystemExclusiveMessage: inout MidiMessage?,
        _ error: inout MidiError?
    ) -> [MidiMessage] {
        var decodedMessages: [MidiMessage] = []

        let packetSize = packet.count
        var timeStamp: UInt16
        var runningStatus: UInt8
        var index: Int

        if packetSize < 1 || packet[0] & 0x80 == 0 {
            error = .invalidPacket(
                "First byte is either missing or does not contain the timestamp MSB (0b11mmmmmm)"
            )
            return []
        }

        let timeStampMSB = UInt16(packet[0] & 0x3F) << 7

        let systemExclusiveContinuation =
            packetSize > 1 && packet[1] & 0x80 == 0

        if pendingSystemExclusiveMessage != nil {
            guard systemExclusiveContinuation else {
                error = .invalidPacket(
                    "Expecting continuation of the pending exclusive message"
                )
                pendingSystemExclusiveMessage = nil
                return []
            }

            timeStamp = UInt16(packet[0] & 0x3F) << 8
            runningStatus = MidiMessageType.systemExclusive.status
            index = 1
        } else if packetSize < 3 {
            // There must be at least 3 bytes (2 for time stamp plus one MIDI status)
            error = .invalidPacket(
                "Packet size (\(packetSize) bytes) is too small for MIDI"
            )
            return []
        } else {
            timeStamp = timeStampMSB + UInt16(packet[1] & 0x7F)
            runningStatus = packet[2]
            index = 3
        }

        while index <= packetSize {
            guard let runningType = MidiMessageType.from(runningStatus) else {
                error = .invalidStatus(
                    "MIDI status byte \(runningStatus) is not supported"
                )
                return []
            }

            let expectedDataSize =
                runningType == .systemExclusive
                ? 0 : runningType.dataHeaders.count

            if index + expectedDataSize > packetSize {
                error = .invalidPacket(
                    "Index \(index) is too large to read expected \(expectedDataSize) bytes for \(runningType.rawValue) in packet of size \(packetSize)"
                )
                return []
            }

            if runningType == .systemExclusive {
                var dataBuffer: [UInt8] = []
                while index < packetSize && packet[index] & 0x80 == 0 {
                    dataBuffer.append(packet[index])
                    index += 1
                }
                if pendingSystemExclusiveMessage == nil {
                    pendingSystemExclusiveMessage =
                        MidiMessage(
                            sourceStamp: timeStamp,
                            type: .systemExclusive,
                            channel: 0xFF,
                            data: dataBuffer
                        )
                } else {
                    pendingSystemExclusiveMessage!.data.append(
                        contentsOf: dataBuffer
                    )
                }
            } else if runningType == .systemExclusiveEnd {
                if pendingSystemExclusiveMessage != nil {
                    decodedMessages.append(pendingSystemExclusiveMessage!)
                    pendingSystemExclusiveMessage = nil
                }
            } else {
                if pendingSystemExclusiveMessage != nil {
                    decodedMessages.append(pendingSystemExclusiveMessage!)
                    pendingSystemExclusiveMessage = nil
                }

                let receivedMessage = MidiMessage(
                    sourceStamp: timeStamp,
                    type: runningType,
                    channel: runningStatus & 0x0F,
                    data: []
                )
                packet[index..<index + expectedDataSize].forEach { value in
                    guard value & 0x80 == 0 else {
                        error = .invalidPacket(
                            "Data byte \(value) in packet of size \(packetSize) is not a data byte"
                        )
                        return
                    }

                    receivedMessage.data.append(value)
                }
                decodedMessages.append(receivedMessage)

                index += expectedDataSize
            }

            if index >= packetSize {
                break
            } else if packet[index] & 0x80 == 0x80 {
                guard index + 1 < packetSize else {
                    error = .invalidPacket("Truncated packet")
                    return []
                }

                timeStamp = timeStampMSB + UInt16(packet[index] & 0x7F)
                runningStatus = packet[index + 1]
                index += 2
            }
        }

        return decodedMessages
    }
}

extension MidiMessage {
    static let BankMSB: UInt8 = 0x00
    static let BankLSB: UInt8 = 0x20
}

extension MidiMessage {
    static let samples1: [MidiMessage] = [
        MidiMessage(
            sourceStamp: 0,
            type: .noteOn,
            channel: 0,
            data: [60, 100]
        ),
        MidiMessage(
            sourceStamp: 12,
            type: .noteOff,
            channel: 0,
            data: [60, 100]
        ),
    ]

    static let samples2: [MidiMessage] = [
        MidiMessage(sourceStamp: 19, type: .note, channel: 0, data: [60, 100]),
        MidiMessage(
            sourceStamp: 53,
            type: .bankProgramChange,
            channel: 0,
            data: [1, 3, 27]
        ),
    ]
}
