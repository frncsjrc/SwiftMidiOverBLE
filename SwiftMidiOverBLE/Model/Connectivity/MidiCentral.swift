//
//  MidiCentral.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 26/07/2025.
//

import CoreBluetooth
import Foundation

@Observable
class MidiCentral: Central {
    static let shared = MidiCentral()

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

    private var discoveredPeripherals: Set<CBPeripheral> = []

    override private init() {
        super.init()

        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true
            ]
        )
    }

    override var scan: Bool {
        get {
            centralManager?.isScanning ?? false
        }

        set {
            DispatchQueue.main.async {
                if newValue {
                    self.startScanning()
                } else {
                    self.stopScanning()
                }
            }
        }
    }

    override func connect(_ peripheral: UUID) {
        if !checkCentral() {
            return
        }
        guard let centralManager else {
            setError(.invalidManager)
            return
        }
        guard
            let target = discoveredPeripherals.first(where: {
                $0.identifier == peripheral
            })
        else {
            setError(.invalidPeripheral)
            return
        }
        print("connecting to ", target)
        centralManager.connect(
            target,
            options: [CBConnectPeripheralOptionEnableAutoReconnect: true]
        )
    }

    override func disconnect(_ peripheral: UUID) {
        if !checkCentral() {
            return
        }
        guard let centralManager else {
            setError(.invalidManager)
            return
        }
        guard
            let target = discoveredPeripherals.first(where: {
                $0.identifier == peripheral
            })
        else {
            setError(.invalidPeripheral)
            return
        }

        cleanup(target)
        centralManager.cancelPeripheralConnection(target)
    }

    override func send(_ message: Message, to peripherals: [UUID] = []) {
        if !checkCentral() {
            return
        }

        let targets: [CBPeripheral] =
            peripherals.isEmpty
            ? discoveredPeripherals.filter({
                remotePeripherals[$0.identifier]?.state ?? .offline
                    == .connected
            })
            : discoveredPeripherals.filter({
                peripherals.contains($0.identifier)
            })

        let packetSize =
            targets.map({ $0.maximumWriteValueLength(for: .withoutResponse) })
            .min() ?? 256

        let packets = MessageManager.shared.encode(message, packetSize)

        print(
            "ready to write \(packets.count) packets to \(targets.count) peripherals"
        )

        for target in targets {
            for packet in packets {
                writeValue(target, packet)
            }
        }
    }

    @MainActor
    func requestRemoteName(for peripheral: UUID) -> String {
        if let target = discoveredPeripherals.first(where: {
            $0.identifier == peripheral
        }) {
            return target.name ?? Constants.unknownRemoteName
        }
        
        if !checkCentral() {
            return Constants.unknownRemoteName
        }
        
        let remotesWithGapService = centralManager?.retrieveConnectedPeripherals(withServices: [Constants.gapService, Constants.midiService])
        let remotePeripheral = remotesWithGapService?.first(where: { $0.identifier == peripheral })
        let remoteGapService = remotePeripheral?.services?.first(where: { $0.uuid == Constants.gapService })
        let remoteDeviceNameCharacteristic = remoteGapService?.characteristics?.first(where: { $0.uuid == Constants.deviceNameCharacteristic })
        let remoteDeviceNameValue = remoteDeviceNameCharacteristic?.value
        if let deviceName = String(bytes: remoteDeviceNameValue ?? Data(), encoding: .utf8) {
            return deviceName.isEmpty ? Constants.unknownRemoteName : deviceName
        } else {
            return Constants.unknownRemoteName
        }
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
            cleanup(peripheral)
        }

        print("start remote peripheral scanning")
        centralManager?.scanForPeripherals(
            withServices: [
                Constants.gapService, Constants.midiService,
            ]
        )
    }

    func stopScanning() {
        print("stop remote peripheral scanning")
        centralManager?.stopScan()
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
            $0.uuid == Constants.midiService
        })
        let cheracteristic = service?.characteristics?.first(where: {
            $0.uuid == Constants.midiDataCharacteristic
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

        let peripheralName = peripheral.name ?? Constants.unknownRemoteName
        let advertisedName =
            (advertisementData[CBAdvertisementDataLocalNameKey] as? String
                ?? "")
        let serviceName = advertisedName.isEmpty ? "" : " (\(advertisedName))"
        let name = "\(peripheralName)\(serviceName)"

        print("full name: \"\(name)\"")

        DispatchQueue.main.async {
            self.discoveredPeripherals.insert(peripheral)
            self.remotePeripherals[peripheral.identifier] = RemoteDetails(
                name: name,
                state: peripheral.state == .connected
                    ? .connected : .disconnected
            )
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        print("Peripheral Connected ", peripheral)
        peripheral.delegate = self
        peripheral.discoverServices([Constants.midiService])

        remotePeripherals[peripheral.identifier]?.state =
            peripheral.state == .connected ? .connected : .disconnected
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

        remotePeripherals[peripheral.identifier]?.state =
            peripheral.state == .connected ? .connected : .disconnected
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

        remotePeripherals[peripheral.identifier]?.state =
            peripheral.state == .connected ? .connected : .disconnected

        // disconnect not being a result of cancelPeripheralConnection
        if let error {
            print("error: ", error)
            setError(.disconnectFailure(error.localizedDescription))
            // not automatically reconnecting
            if !isReconnecting {
                self.connect(peripheral.identifier)
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
            if service.uuid == Constants.midiService {
                peripheral.discoverCharacteristics(
                    [Constants.midiDataCharacteristic],
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
            if characteristic.uuid == Constants.midiDataCharacteristic {
                peripheral.readValue(for: characteristic)
                peripheral.discoverDescriptors(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)
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
            DispatchQueue.main.async {
                MessageManager.shared.decode(
                    data,
                    from: peripheral.identifier,
                    at: .bluetoothMidiCentral,
                    report: &self.error
                )
            }
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

}  // CBPeripheralDelegate extension
