//
//  CentralSetupView.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 01/08/2025.
//

import SwiftUI

struct SetupView: View {
    @Binding var peripheral: Peripheral
    @Binding var central: Central

    var body: some View {
        Group {
            HStack {
                Toggle(
                    isOn: $peripheral.advertize
                ) {
                    Text(
                        String(
                            localized: "Advertize",
                            comment: "Toggle advertize text"
                        )
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                Spacer()
                Toggle(
                    isOn: $central.scan
                ) {
                    Text(String(localized: "Scan", comment: "Toggle scan text"))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                Spacer()
            }
            .padding()
            Section(
                String(
                    localized: "Remote Centrals",
                    comment: "Section header for remote centrals in setup view"
                )
            ) {
                ScrollView {
                    if peripheral.remoteCentrals.isEmpty {
                        HStack {
                            Spacer()
                            Text(
                                String(
                                    localized: "No subscribed remote centrals",
                                    comment:
                                        "Warn no remote centrals have subscribed"
                                )
                            )
                            .foregroundColor(.secondary)
                            .italic()
                            Spacer()
                        }
                        .padding(.top)
                    } else {
                        ForEach(
                            peripheral.remoteCentrals.keys.sorted(),
                            id: \.self
                        ) { central in
                            RemoteCentralView(
                                peripheral: $peripheral,
                                identifier: central
                            )
                        }
                    }
                }
            }

            Section(
                String(
                    localized: "Remote Peripherals",
                    comment:
                        "Section header for remote peripherals in setup view"
                )
            ) {
                ScrollView {
                    if central.remotePeripherals.isEmpty {
                        HStack {
                            Spacer()
                            Text(
                                String(
                                    localized:
                                        "No remote peripherals discovered",
                                    comment:
                                        "Warn no peripherals have been discovered"
                                )
                            )
                            .foregroundColor(.secondary)
                            .italic()
                            Spacer()
                        }
                        .padding(.top)
                    } else {
                        ForEach(
                            central.remotePeripherals.keys.sorted(),
                            id: \.self
                        ) { peripheral in
                            RemotePeripheralView(
                                central: $central,
                                identifier: peripheral
                            )
                        }
                    }
                }
            }

            VStack {
                Button(
                    "Sample 1",
                    systemImage: "play",
                    action: {
                        central.send(Message.samples1[0])
                    }
                )

                Button(
                    "Sample 2",
                    systemImage: "play",
                    action: {
                        central.send(Message.samples2[0])
                    }
                )

                Button(
                    "Sample 3",
                    systemImage: "play",
                    action: {
                        central.send(Message.samples2[1])
                    }
                )
            }
            .padding(.vertical)
        }
    }
}

#Preview("Populated") {
    @Previewable @State var peripheral = Peripheral()
    @Previewable @State var central = Central()

    peripheral.remoteCentrals = Peripheral.remoteSamples1
    central.remotePeripherals = Central.remoteSamples1

    return SetupView(peripheral: $peripheral, central: $central)
}

#Preview("Empty") {
    @Previewable @State var peripheral = Peripheral()
    @Previewable @State var central = Central()

    return SetupView(peripheral: $peripheral, central: $central)
}
