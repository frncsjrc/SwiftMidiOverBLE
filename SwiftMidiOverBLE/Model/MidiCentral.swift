//
//  MidiCentral.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 26/07/2025.
//

import CoreBluetooth
import Foundation

@Observable
class MidiCentral: NSObject {
    var error: MidiError? = nil {
        didSet {
            if error != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.error = nil
                }
            }
        }
    }

    private var centralManager: CBCentralManager?
    private var timeManager: MidiTimeManager = MidiTimeManager.shared

    var discoveredPeripherals: [CBPeripheral: MidiDefinitions.PeerDetails] = [:]
    var connectedPeripherals: [CBPeripheral: MidiDefinitions.ReceivedData] = [:]

    override init() {
        super.init()

        //        let bundleIdentifier = Bundle.main.bundleIdentifier
        //        let centralIdentifier =
        //            "\(bundleIdentifier ?? "FrncsJRClement").MIDIBluetoothCentral"

        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true
                    //                CBCentralManagerOptionRestoreIdentifierKey: centralIdentifier,
            ]
        )
    }
}

extension MidiCentral {
    private func checkCentral() -> Bool {
        if centralManager?.state != .poweredOn {
            self.error = .bluetoothNotAvailable
            return false
        }
        return true
    }

    private func setError(_ error: MidiError?) {
        DispatchQueue.main.async {
            self.error = error
        }
    }

    @MainActor
    func startScanning() {
        if !checkCentral() {
            return
        }
        for peripheral in discoveredPeripherals {
            cleanup(peripheral.key)
        }
        self.discoveredPeripherals.removeAll()

        print("start remote peripheral scanning")
        centralManager?.scanForPeripherals(
            withServices: [MidiDefinitions.serviceUUID]
        )
    }

    func stopScanning() {
        centralManager?.stopScan()
    }

    func connect(_ peripheral: CBPeripheral) {
        if !checkCentral() {
            return
        }
        guard let centralManager else {
            setError(.invalidManager)
            return
        }
        print("connecting to ", peripheral)
        centralManager.connect(
            peripheral,
            options: [CBConnectPeripheralOptionEnableAutoReconnect: true]
        )
    }

    func disconnect(_ peripheral: CBPeripheral) {
        if !checkCentral() {
            return
        }
        guard let centralManager else {
            setError(.invalidManager)
            return
        }

        cleanup(peripheral)
        centralManager.cancelPeripheralConnection(peripheral)
    }

    func readCharacteristicValue(
        _ peripheral: CBPeripheral,
        for characteristic: CBCharacteristic
    ) {
        if !checkCentral() {
            return
        }
        peripheral.readValue(for: characteristic)
    }

    func readDescriptorValue(
        _ peripheral: CBPeripheral,
        for descriptor: CBDescriptor
    ) {
        if !checkCentral() {
            return
        }
        peripheral.readValue(for: descriptor)
    }

    func writeValue(_ peripheral: CBPeripheral, _ data: Data) {
        if !checkCentral() {
            return
        }
        let service = peripheral.services?.first(where: {
            $0.uuid == MidiDefinitions.serviceUUID
        })
        let cheracteristic = service?.characteristics?.first(where: {
            $0.uuid == MidiDefinitions.characteristicUUID
        })
        guard let cheracteristic else {
            setError(.invalidCharacteristic)
            return
        }
        print("Writing data: \(data) to peripheral\n\(peripheral.description)")
        peripheral.writeValue(data, for: cheracteristic, type: .withoutResponse)
    }

    private func cleanup(_ peripheral: CBPeripheral) {
        if peripheral.state == .connected {
            for service in (peripheral.services ?? [] as [CBService]) {
                for characteristic
                    in (service.characteristics ?? [] as [CBCharacteristic])
                {
                    peripheral.setNotifyValue(false, for: characteristic)
                }
            }
        }
    }
}

extension MidiCentral: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOff {
            setError(.bluetoothNotAvailable)
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        print("did discover peripheral")
        print(peripheral)
        
        print("advertisementData: \(advertisementData)")
        
        let peripheralName = peripheral.name ?? "Unknown"
        let advertisedName =
            (advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? "")
        let serviceName = advertisedName.isEmpty ? "" : " (\(advertisedName))"
        let name = "\(peripheralName)\(serviceName)"
        
        print("full name: \(name)")

        if discoveredPeripherals[peripheral] == nil {
            discoveredPeripherals[peripheral] = MidiDefinitions.PeerDetails(
                name: name,
                connected: peripheral.state == .connected
            )
        } else {
            discoveredPeripherals[peripheral]!.name = name
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        print("Peripheral Connected ", peripheral)
        peripheral.delegate = self
        peripheral.discoverServices([MidiDefinitions.serviceUUID])

        discoveredPeripherals[peripheral]?.connected =
            peripheral.state == .connected
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        print("Failed to connect to ", peripheral)
        cleanup(peripheral)
        if let error {
            setError(.connectFailure(error.localizedDescription))
        }

        discoveredPeripherals[peripheral]?.connected =
            peripheral.state == .connected
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        timestamp: CFAbsoluteTime,
        isReconnecting: Bool,
        error: (any Error)?
    ) {
        print("peripheral disconnected: ", peripheral)
        print("is reconnecting: ", isReconnecting)

        discoveredPeripherals[peripheral]?.connected =
            peripheral.state == .connected

        // disconnect not being a result of cancelPeripheralConnection
        if let error {
            print("error: ", error)
            setError(.disconnectFailure(error.localizedDescription))
            // not automatically reconnecting
            if !isReconnecting {
                self.connect(peripheral)
            }
        }
    }

}  // CBCentralManagerDelegate extension

extension MidiCentral: CBPeripheralDelegate {
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: (any Error)?
    ) {
        print("service discovered for peripheral:", peripheral)
        if let error {
            self.setError(.serviceDiscoveryFailure(error.localizedDescription))
            return
        }
        for service in peripheral.services ?? [] {
            if service.uuid == MidiDefinitions.serviceUUID {
                peripheral.discoverCharacteristics(
                    [MidiDefinitions.characteristicUUID],
                    for: service
                )
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didModifyServices invalidatedServices: [CBService]
    ) {
        print("didModifyServices: ", invalidatedServices)
        peripheral.discoverServices(invalidatedServices.map({ $0.uuid }))
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverIncludedServicesFor service: CBService,
        error: (any Error)?
    ) {
        print("discovered included services")
        print("included services :", service.includedServices as Any)

        if let error {
            setError(
                .includedServiceDiscoveryFailure(error.localizedDescription)
            )
            return
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: (any Error)?
    ) {
        print("characteristic found for service: ", service)
        print(service.characteristics as Any)

        for characteristic in service.characteristics ?? [] {
            if characteristic.uuid == MidiDefinitions.characteristicUUID {
                peripheral.readValue(for: characteristic)
                peripheral.discoverDescriptors(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)

                if connectedPeripherals[peripheral] == nil {
                    connectedPeripherals[peripheral] =
                        MidiDefinitions.ReceivedData()
                }
            }
        }

        if let error {
            setError(
                .characteristicDiscoveryFailure(error.localizedDescription)
            )
            return
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        print("descriptor found for characteristic: ", characteristic)
        print(characteristic.descriptors as Any)

        if let error {
            setError(.descriptorDiscoveryFailure(error.localizedDescription))
            return
        }
        if let userDescriptor = characteristic.descriptors?.first(where: {
            $0.uuid == CBUUID(string: CBUUIDCharacteristicUserDescriptionString)
        }) {
            self.readDescriptorValue(peripheral, for: userDescriptor)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        if let error {
            setError(.notificationFailure(error.localizedDescription))
        }

    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        print("didWriteValueFor")

        if let error {
            print("error writing value")
            setError(.writeError(error.localizedDescription))
            return
        } else if !characteristic.isNotifying {
            print("reading value")
            self.readCharacteristicValue(peripheral, for: characteristic)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        print("didUpdateValueFor characteristic", characteristic)

        if let error {
            setError(.characteristicUpdateFailure(error.localizedDescription))
            return
        }
        if let data = characteristic.value, !data.isEmpty {
            decodePacket(peripheral, data)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor descriptor: CBDescriptor,
        error: (any Error)?
    ) {
        print("didUpdateValueFor descriptor", descriptor)
        if let error {
            setError(.descriptorDiscoveryFailure(error.localizedDescription))
            return
        }
    }

    private func decodePacket(_ requester: CBPeripheral, _ packet: Data) {
        guard let messageBuffers = connectedPeripherals[requester] else {
            self.error = .invalidCentral(
                "Can't decode packet for unconnected peripheral: \(requester.identifier)"
            )
            return
        }

        var pendingSystemExclusiveMessage = messageBuffers
            .pendingSystemExclusiveMessage

        let decodedMessages = MidiMessage.decodePacket(
            packet,
            &pendingSystemExclusiveMessage,
            &error
        )

        if error == nil {
            connectedPeripherals[requester]!.pendingSystemExclusiveMessage =
                pendingSystemExclusiveMessage
            connectedPeripherals[requester]!.messages.append(
                contentsOf: decodedMessages
            )
        } else {
            connectedPeripherals[requester]!.pendingSystemExclusiveMessage = nil
        }
    }

    func send(_ message: MidiMessage, to peripherals: [CBPeripheral] = []) {
        if !checkCentral() {
            return
        }

        let targets: [CBPeripheral] =
            peripherals.isEmpty
            ? discoveredPeripherals.keys.filter({ $0.state == .connected })
            : peripherals

        let mtu =
            targets.map({ $0.maximumWriteValueLength(for: .withoutResponse) })
            .min() ?? 256

        let packets: [Data] = message.encodePackets(timeManager, mtu)

        print(
            "ready to write \(packets.count) packets to \(targets.count) peripherals"
        )

        for target in targets {
            for packet in packets {
                writeValue(target, packet)
            }
        }
    }

}  // CBPeripheralDelegate extension
