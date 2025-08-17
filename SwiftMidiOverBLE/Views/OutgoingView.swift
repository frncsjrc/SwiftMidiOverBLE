//
//  OutgoingView.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 16/08/2025.
//

import SwiftUI

struct OutgoingView: View {
    typealias AvailableDestination = (port: Port, remote: UUID, label: String)

    @Binding var peripheral: Peripheral
    @Binding var central: Central

    private var availableDestinations: [AvailableDestination] {
        var result: [AvailableDestination] = []

        let connectedRemoteCentrals = peripheral.remoteCentrals.filter {
            $0.value.state == .connected
        }
        for remoteCentral in connectedRemoteCentrals {
            result.append(
                (
                    port: .bluetoothMidiPeripheral,
                    remote: remoteCentral.key,
                    label: remoteCentral.value.name
                        == Constants.unknownRemoteName
                        ? remoteCentral.key.uuidString
                        : remoteCentral.value.name
                )
            )

        }

        let connectedRemotePeripherals = central.remotePeripherals.filter {
            $0.value.state == .connected
        }
        for remotePeripheral in connectedRemotePeripherals {
            result.append(
                (
                    port: .bluetoothMidiCentral,
                    remote: remotePeripheral.key,
                    label: remotePeripheral.value.name
                )
            )
        }
        
        return result
    }

    @State var destinationIndex: Int = 0

    var body: some View {
        VStack(alignment: .center) {
            if availableDestinations.isEmpty {
                Text(
                    String(
                        localized: "No destinations available",
                        comment:
                            "Warn no destinations are available in outgoing view"
                    )
                )
                .foregroundColor(.secondary)
                .italic()
            } else {
                Picker(
                    selection: $destinationIndex,
                    label: Text(
                        String(
                            localized: "Destination",
                            comment:
                                "Label for destination picker in outgoing view"
                        )
                    )
                ) {
                    ForEach(Array(0..<availableDestinations.count), id: \.self)
                    {
                        index in
                        if index < availableDestinations.count {
                            HStack {
                                self.availableDestinations[index].port.icon
                                Text(self.availableDestinations[index].label)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .onChange(of: availableDestinations.count) {
                    destinationIndex = 0
                }
            }
            HStack {
                Button(
                    action: {
                        send(index: 0)
                    }
                ) {
                    Label(
                        String(
                            localized: "Sample 1",
                            comment: "Label for the first outgoing sample"
                        ),
                        systemImage: "play",
                    )
                }
                Spacer()
                Button(
                    action: {
                        send(index: 1)
                    }
                ) {
                    Label(
                        String(
                            localized: "Sample 2",
                            comment: "Label for the first outgoing sample"
                        ),
                        systemImage: "play",
                    )
                }
                Spacer()
                Button(
                    action: {
                        send(index: 2)
                    }
                ) {
                    Label(
                        String(
                            localized: "Sample 3",
                            comment: "Label for the first outgoing sample"
                        ),
                        systemImage: "play",
                    )
                }
            }
            .disabled(availableDestinations.isEmpty)
            .padding(.horizontal, 20)
        }
    }

    private func send(index: Int) {
        guard
            let destination = availableDestinations[destinationIndex]
                as AvailableDestination?
        else {
            return
        }
        let message =
            switch index {
            case 0:
                Message.samples1[0]
            case 1:
                Message.samples2[0]
            default:
                Message.samples2[1]
            }
        message.port = destination.port
        message.remote = destination.remote
        if destination.port == .bluetoothMidiCentral {
            central.send(message)
        } else {
            peripheral.send(message)
        }
    }
}

#Preview("Populated") {
    @Previewable @State var peripheral = Peripheral()
    @Previewable @State var central = Central()

    peripheral.remoteCentrals = Peripheral.remoteSamples1
    central.remotePeripherals = Central.remoteSamples1

    return OutgoingView(peripheral: $peripheral, central: $central)
}

#Preview("Empty") {
    @Previewable @State var peripheral = Peripheral()
    @Previewable @State var central = Central()

    return OutgoingView(peripheral: $peripheral, central: $central)
}
