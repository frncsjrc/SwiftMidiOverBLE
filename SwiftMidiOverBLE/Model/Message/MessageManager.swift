//
//  MidiReadDelegate.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 02/08/2025.
//

import CoreBluetooth
import Foundation

class MessageManager {
    static let shared = MessageManager()

    private let timeKeeper: TimeKeeper = .shared

    var delegate: MessageManagerDelegate? = nil

    private var messageBuffer: [Message] = []

    func encode(_ message: Message, _ packetSize: Int) -> [Data] {
        var encodedPackets: [Data] = []

        var timeStamp = timeKeeper.elapsedTime() & 0x1FFF
        var timeStampMSB: UInt8 = 0x80 | UInt8(timeStamp >> 7)
        var timeStampLSB: UInt8 = 0x80 | UInt8(timeStamp & 0x7F)
        let status = message.status

        var encodedPacket = Data()
        encodedPacket.append(timeStampMSB)
        encodedPacket.append(timeStampLSB)
        encodedPacket.append(status)

        if message.type == .systemExclusive {
            let maxContinuousDataSize = packetSize - 5
            let maxSplitDataSize = packetSize - 3

            var startIndex: Int = 0
            var endIndex: Int =
                message.data.count <= maxContinuousDataSize
                ? message.data.count : maxSplitDataSize

            while endIndex < message.data.count {
                encodedPacket.append(
                    contentsOf: message.data[startIndex..<endIndex]
                )

                if endIndex == message.data.count {
                    encodedPacket.append(timeStampLSB)
                    encodedPacket.append(
                        MessageType.systemExclusiveEnd.status
                    )
                }

                encodedPackets.append(encodedPacket)

                timeStamp = timeKeeper.elapsedTime() & 0x1FFF
                timeStampMSB = 0x80 | UInt8(timeStamp >> 7)
                timeStampLSB = 0x80 | UInt8(timeStamp & 0x7F)

                startIndex = endIndex
                endIndex = min(message.data.count, endIndex + maxSplitDataSize)

                encodedPacket.removeAll(keepingCapacity: true)
                encodedPacket.append(timeStampMSB)
            }
        } else if message.type == .note {
            message.data.forEach { encodedPacket.append($0) }
            encodedPacket.append(timeStampLSB)
            encodedPacket.append(
                MessageType.noteOff.status | message.channel
            )
            message.data.forEach { encodedPacket.append($0) }

            encodedPackets.append(encodedPacket)
        } else if message.type == .bankProgramChange {
            encodedPacket.append(Message.BankMSB)
            encodedPacket.append(message.data.count >= 1 ? message.data[0] : 0)
            encodedPacket.append(Message.BankLSB)
            encodedPacket.append(message.data.count >= 2 ? message.data[1] : 0)
            encodedPacket.append(timeStampLSB)
            encodedPacket.append(
                MessageType.programChange.status | message.channel
            )
            encodedPacket.append(message.data.count >= 3 ? message.data[2] : 0)

            encodedPackets.append(encodedPacket)
        } else {
            message.data.forEach { encodedPacket.append($0) }

            encodedPackets.append(encodedPacket)
        }

        return encodedPackets
    }

    @MainActor
    func decode(
        _ packet: Data,
        from source: UUID,
        at port: Port,
        report error: inout MidiError?
    ) {
        guard let delegate else {
            print(
                "received \(packet) from \(source) will be lost because no delegate is set"
            )
            return
        }

        var decodedMessages: [Message] = []

        let packetSize = packet.count
        var timeStamp: UInt16
        var runningStatus: UInt8
        var index: Int

        if packetSize < 1 || packet[0] & 0x80 == 0 {
            error = .invalidPacket(
                "First byte is either missing or does not contain the timestamp MSB (0b11mmmmmm)"
            )
        }

        let timeStampMSB = UInt16(packet[0] & 0x3F) << 7

        let systemExclusiveContinuation =
            packetSize > 1 && packet[1] & 0x80 == 0

        var pendingExclusiveMessage: Message? = pendingExclusiveMessage(
            from: source,
            at: port
        )

        if pendingExclusiveMessage != nil {
            guard systemExclusiveContinuation else {
                error = .invalidPacket(
                    "Expecting continuation of the pending exclusive message"
                )
                removePendingExclusiveMessage(from: source, at: port)
                return
            }

            timeStamp = UInt16(packet[0] & 0x3F) << 8
            runningStatus = MessageType.systemExclusive.status
            index = 1
        } else if packetSize < 3 {
            // There must be at least 3 bytes (2 for time stamp plus one MIDI status)
            error = .invalidPacket(
                "Packet size (\(packetSize) bytes) is too small for MIDI"
            )
            return
        } else {
            timeStamp = timeStampMSB + UInt16(packet[1] & 0x7F)
            runningStatus = packet[2]
            index = 3
        }

        while index <= packetSize {
            guard let runningType = MessageType.from(runningStatus) else {
                error = .invalidStatus(
                    "MIDI status byte \(runningStatus) is not supported"
                )
                return
            }

            let expectedDataSize =
                runningType == .systemExclusive
                ? 0 : runningType.dataHeaders.count

            if index + expectedDataSize > packetSize {
                error = .invalidPacket(
                    "Index \(index) is too large to read expected \(expectedDataSize) bytes for \(runningType.rawValue) in packet of size \(packetSize)"
                )
            }

            if runningType == .systemExclusive {
                var dataBuffer: [UInt8] = []
                while index < packetSize && packet[index] & 0x80 == 0 {
                    dataBuffer.append(packet[index])
                    index += 1
                }
                if pendingExclusiveMessage == nil {
                    pendingExclusiveMessage =
                        Message(
                            port: port,
                            source: source,
                            sourceStamp: timeStamp,
                            type: .systemExclusive,
                            channel: 0xFF,
                            data: dataBuffer
                        )
                } else {
                    pendingExclusiveMessage?.data.append(
                        contentsOf: dataBuffer
                    )
                }
            } else if runningType == .systemExclusiveEnd {
                if pendingExclusiveMessage != nil {
                    decodedMessages.append(pendingExclusiveMessage!)
                    removePendingExclusiveMessage(from: source, at: port)
                }
            } else {
                if pendingExclusiveMessage != nil {
                    decodedMessages.append(pendingExclusiveMessage!)
                    removePendingExclusiveMessage(from: source, at: port)
                }

                var receivedMessage: Message? = Message(
                    port: port,
                    source: source,
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

                    receivedMessage?.data.append(value)
                }

                receivedMessage = processCompound(
                    message: receivedMessage,
                    report: &error
                )

                if let receivedMessage {
                    decodedMessages.append(receivedMessage)
                }

                index += expectedDataSize
            }

            if index >= packetSize {
                break
            } else if packet[index] & 0x80 == 0x80 {
                guard index + 1 < packetSize else {
                    error = .invalidPacket("Truncated packet")
                    break
                }

                timeStamp = timeStampMSB + UInt16(packet[index] & 0x7F)
                runningStatus = packet[index + 1]
                index += 2
            }
        }

        delegate.process(incoming: decodedMessages)
    }

    private func pendingExclusiveMessage(from source: UUID, at port: Port)
        -> Message?
    {
        return self.messageBuffer.first {
            $0.port == port && $0.remote == source
                && $0.type == .systemExclusive
        }
    }

    private func updatePendingExclusiveMessage(
        from source: UUID,
        at port: Port,
        with message: Message?
    ) {
        guard let message = message else {
            self.removePendingExclusiveMessage(from: source, at: port)
            return
        }

        if let index = self.messageBuffer.firstIndex(where: {
            $0.port == port && $0.remote == source
                && $0.type == .systemExclusive
        }) {
            self.messageBuffer[index] = message
        } else {
            self.messageBuffer.append(message)
        }
    }

    private func removePendingExclusiveMessage(from source: UUID, at port: Port)
    {
        self.messageBuffer.removeAll {
            $0.port == port && $0.remote == source
                && $0.type == .systemExclusive
        }
    }

    private func processCompound(
        message: Message?,
        report error: inout MidiError?
    ) -> Message? {
        guard let message = message, let port = message.port, let source = message.remote else {
            return nil
        }

        let bankProgramChangeBufferIndex = self.messageBuffer.firstIndex {
            $0.port == port && $0.remote == source
                && $0.type == .bankProgramChange
        }

        let bankProgramChangeBuffer: Message? =
            bankProgramChangeBufferIndex == nil
            ? nil : self.messageBuffer[bankProgramChangeBufferIndex!]

        if message.type == .programChange
            || (message.type == .controlChange
                && message.data[0] & Message.BankMask == 0x00)
        {
            if message.type == .programChange {
                // - Program change is ok when alone or combined with a Bank MSB and LSB pair
                if let bankProgramChangeBuffer = bankProgramChangeBuffer {
                    if bankProgramChangeBuffer.data.count < 2 {
                        error = .decodeFailure(
                            "Bank LSB is missing between bank MSB and program change"
                        )
                        messageBuffer.removeAll {
                            $0.port == port && $0.remote == source
                                && $0.type == .bankProgramChange
                        }
                        return nil
                    } else {
                        if bankProgramChangeBuffer.data.count == 2 {
                            bankProgramChangeBuffer.data.append(message.data[0])
                        } else {
                            bankProgramChangeBuffer.data[2] = message.data[0]
                        }
                        message.type = .bankProgramChange
                        message.data = bankProgramChangeBuffer.data
                        return message
                    }
                } else {
                    return message
                }
            } else if message.data[0] == Message.BankMSB {
                // - Bank MSB is ok when alone or after a previously completed bank program change sequence
                if bankProgramChangeBuffer == nil
                    || bankProgramChangeBuffer?.data.count == 3
                {
                    message.type = .bankProgramChange
                    if let bankProgramChangeBufferIndex {
                        self.messageBuffer[bankProgramChangeBufferIndex].data =
                            [message.data[1]]
                    } else {
                        messageBuffer.append(message)
                    }
                } else {
                    error = .decodeFailure(
                        "Unexpected Bank MSB"
                    )
                }
            } else {
                // - Bank LSB is only valid following a bank MSB
                if let bankProgramChangeBufferIndex,
                    bankProgramChangeBuffer?.data.count == 1
                {
                    self.messageBuffer[bankProgramChangeBufferIndex].data
                        .append(message.data[1])
                } else {
                    error = .decodeFailure(
                        "Unexpected Bank LSB"
                    )
                }
            }

            return nil
        } else {
            if let bankProgramChangeBuffer = bankProgramChangeBuffer,
                bankProgramChangeBuffer.data.count != 3
            {
                error = .decodeFailure(
                    "Interrupted bank program change sequence"
                )
                messageBuffer.removeAll {
                    $0.port == port && $0.remote == source
                        && $0.type == .bankProgramChange
                }
            }

            return message
        }
    }
}
