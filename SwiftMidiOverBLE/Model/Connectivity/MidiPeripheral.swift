//
//  MidiController.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 25/05/2025.
//

//
//  MidiBridge.swift
//  MidiCI
//
//  Created by François Jean Raymond CLÉMENT on 18/05/2025.
//

import CoreBluetooth
import Foundation

@Observable
class MidiPeripheral: Peripheral {
    typealias DeviceName = String

    static let shared = MidiPeripheral()

    var error: MidiError? = nil {
        didSet {
            if error != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.error = nil
                }
            }
        }
    }

    private(set) var peripheralName = "D2Ltest"
    private let peripheralManufacturer = "François Jean Raymond CLÉMENT"

    private var peripheralManager: CBPeripheralManager?
    // A because CoreBluetooth confuse GAP and GATT, a central manager is required to access
    // some subscriber services such as
    private var centralManager: CBCentralManager?

    private var midiService: CBMutableService?
    private var midiCharacteristic: CBMutableCharacteristic?
    private var midiData: Data = Data()

    private var subscribedCentrals: Set<CBCentral> = []
    private var discoveredPeripherals: Set<CBPeripheral> = []

    override private init() {
        super.init()

        let bundleIdentifier = Bundle.main.bundleIdentifier
        let peripheralIdentifier =
            "\(bundleIdentifier ?? "FrncsJRClement").MIDIBluetoothPeripheral"

        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: nil,
            options: [
                CBPeripheralManagerOptionShowPowerAlertKey: true,
                CBPeripheralManagerOptionRestoreIdentifierKey:
                    peripheralIdentifier,
            ]
        )

        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true
            ]
        )
    }

    override var advertize: Bool {
        get {
            peripheralManager?.isAdvertising ?? false
        }

        set {
            DispatchQueue.main.async {
                self.updateAdvertising(newValue)
            }
        }
    }

    override func startup() {
        DispatchQueue.main.async {
            self.addMidiServiceIfNeeded()
        }
    }

    override func send(_ message: Message, to centrals: [UUID] = []) {
        if !checkPeripheral() {
            return
        }

        let targets: [CBCentral] =
            centrals.isEmpty
            ? Array(subscribedCentrals)
            : subscribedCentrals.filter {
                centrals.contains($0.identifier)
            }

        let packetSize =
            targets.map({ $0.maximumUpdateValueLength }).min() ?? 256

        let packets = MessageManager.shared.encode(message, packetSize)

        packets.forEach {
            peripheralManager!.updateValue(
                $0,
                for: midiCharacteristic!,
                onSubscribedCentrals: targets
            )
        }
    }
}

extension MidiPeripheral {

    private func checkPeripheral() -> Bool {
        if peripheralManager?.state != .poweredOn {
            self.error = .bluetoothNotAvailable
            return false
        }

        guard midiService != nil else {
            self.error = .invalidService
            return false
        }

        guard midiCharacteristic != nil else {
            self.error = .invalidCharacteristic
            return false
        }

        return true
    }

    private func validateCharacteristic(
        _ characteristic: CBMutableCharacteristic?
    ) -> Bool {
        if let characteristic {
            if characteristic.value != nil
                && (characteristic.properties != .read
                    || characteristic.permissions != .readable)
            {
                self.error = .addServiceError(
                    "Characteristics with cached values must be read-only"
                )
                return false
            }
            if (characteristic.properties.contains(.read)
                && !characteristic.permissions.contains(.readable))
                || ((characteristic.properties.contains(.write)
                    || characteristic.properties.contains(.writeWithoutResponse))
                    && !characteristic.permissions.contains(.writeable))
            {
                self.error = .addServiceError(
                    "Permission and Properties mismatch."
                )
                return false
            }
            if characteristic.properties.contains(.broadcast)
                || characteristic.properties.contains(.extendedProperties)
            {
                self.error = .addServiceError(
                    "Broadcast and extended properties are not supported for local peripheral service."
                )
                return false

            }
        }
        return true
    }

    @MainActor
    func addMidiServiceIfNeeded() {
        if midiService != nil {
            return
        }

        guard peripheralManager?.state == .poweredOn
        else {
            self.error = .bluetoothNotAvailable
            return
        }

        midiService = CBMutableService(
            type: MidiIdentifiers.midiService,
            primary: true,
        )

        guard let midiService else {
            self.error = .invalidService
            return
        }

        midiCharacteristic = CBMutableCharacteristic(
            type: MidiIdentifiers.midiDataCharacteristic,
            properties: [
                .read, .writeWithoutResponse, .notify,
                .notifyEncryptionRequired,
            ],
            value: nil,
            permissions: [
                .readable, .writeable, .readEncryptionRequired,
                .writeEncryptionRequired,
            ]
        )

        guard let midiCharacteristic, validateCharacteristic(midiCharacteristic)
        else {
            self.error = .invalidCharacteristic
            return
        }

        print("created service and characteristic")
        midiService.characteristics = [midiCharacteristic]
        midiService.includedServices = []
        peripheralManager!.add(midiService)
    }

    @MainActor
    private func updateAdvertising(_ advertize: Bool) {
        addMidiServiceIfNeeded()

        if !checkPeripheral() {
            return
        }

        if advertize && !peripheralManager!.isAdvertising {
            print("about to start advertising")
            peripheralManager!.startAdvertising([
                CBAdvertisementDataServiceUUIDsKey: [
                    MidiIdentifiers.midiService
                ],
                CBAdvertisementDataLocalNameKey: peripheralName,
            ])
            
            // Scan peripherals with GAP service to retrieve subscriber names
            centralManager?.scanForPeripherals(withServices: [
                MidiIdentifiers.gapService
            ])
        } else if !advertize && peripheralManager!.isAdvertising {
            print("about to stop advertising")
            peripheralManager!.stopAdvertising()
            centralManager?.stopScan()
        }
    }

    @MainActor
    private func requestName(from central: CBCentral) {
        guard
            let peripheral = centralManager?.retrieveConnectedPeripherals(
                withServices: [MidiIdentifiers.gapService]).first(where: {
                    $0.identifier == central.identifier
                })
        else {
            return
        }

        guard peripheral.state == .connected else {
            centralManager?.connect(peripheral)
            return
        }

        guard
            let gapService = peripheral.services?.first(where: {
                $0.uuid == MidiIdentifiers.gapService
            })
        else {
            peripheral.discoverServices([MidiIdentifiers.gapService])
            return
        }

        guard
            let deviceNameCharacteristic =
                gapService.characteristics?.first(where: {
                    $0.uuid == MidiIdentifiers.deviceNameCharacteristic
                })
        else {
            peripheral.discoverCharacteristics(
                [MidiIdentifiers.deviceNameCharacteristic],
                for: gapService
            )
            return
        }

        guard let deviceName = deviceNameCharacteristic.value else { return }

        self.remoteCentrals[central.identifier]?.name =
            String(data: deviceName, encoding: .utf8) ?? "Unknown"
    }

}

extension MidiPeripheral: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("state changed: ", peripheral.state)

        if peripheral.state != .poweredOn {
            self.error = .bluetoothNotAvailable
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        willRestoreState dict: [String: Any]
    ) {
        print("will restore: ", dict)

        let previousServices =
            dict[CBPeripheralManagerRestoredStateServicesKey]
            as? [CBMutableService] ?? []

        DispatchQueue.main.async {
            if previousServices.count == 0 { return }
            self.midiService = previousServices[0]
            self.midiCharacteristic =
                self.midiService?.characteristics?.first
                as? CBMutableCharacteristic
            if let characteristic = self.midiCharacteristic,
                let centrals = characteristic.subscribedCentrals
            {
                centrals.forEach {
                    self.subscribedCentrals.insert($0)
                    self.remoteCentrals[$0.identifier]? = RemoteDetails(
                        name: "Unknown",
                        state: .connected
                    )
                    self.requestName(from: $0)
                }
            }
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didAdd service: CBService,
        error: (any Error)?
    ) {
        DispatchQueue.main.async {
            if let error {
                self.midiService = nil
                self.error = .addServiceError(error.localizedDescription)
                return
            }
        }
    }

    // communication related
    func peripheralManagerDidStartAdvertising(
        _ peripheral: CBPeripheralManager,
        error: (any Error)?
    ) {
        print("did start advertising: \(String(describing: error))")
        if let error {
            DispatchQueue.main.async {
                self.advertize = false
                self.error = .startAdvertisingError(error.localizedDescription)
            }
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        print("subscriber: ", central)
        print("characteristic: ", characteristic)

        DispatchQueue.main.async {
            let currentName = self.remoteCentrals[central.identifier]?.name
            if currentName != nil && currentName != "Unknown" {
                self.remoteCentrals[central.identifier]?.state = .connected
            } else {
                self.remoteCentrals[central.identifier] = RemoteDetails(
                    name: "Unknown",
                    state: .connected
                )
                self.requestName(from: central)
            }
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        DispatchQueue.main.async {
            self.remoteCentrals[central.identifier]?.state = .disconnected
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveRead request: CBATTRequest
    ) {
        print("peripheral receive read request")
        // set the value of the request to be what we want the central to receive.
        // Otherwise, central side will always receive an empty value in didUpdateValueFor method
        request.value = self.midiData
        peripheral.respond(to: request, withResult: .success)

    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveWrite requests: [CBATTRequest]
    ) {
        print("peripheral receive write request")
        if let firstRequest = requests.first {
            DispatchQueue.main.async {
                peripheral.respond(to: firstRequest, withResult: .success)
            }
        }

        for request in requests {
            if var packet: Data = request.value {
                packet = packet.dropFirst(request.offset)
                print(
                    "processing write request from central \(request.central.identifier.uuidString)"
                )
                DispatchQueue.main.async {
                    MessageManager.shared.decode(
                        packet,
                        from: request.central.identifier,
                        at: .bluetoothMidiPeripheral,
                        report: &self.error
                    )
                }
            }
        }
    }
}

/*
 * The central manager is used solely to retrieve the Device Name characteristic (0x2A00) from the GAP service (0x1800) for subscribed centrals
 */
extension MidiPeripheral: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOff {
            self.error = .bluetoothNotAvailable
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
    }

    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        print("Peripheral Connected ", peripheral)
        self.discoveredPeripherals.insert(peripheral)
        peripheral.delegate = self
        peripheral.discoverServices([MidiIdentifiers.gapService])
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        print("Failed to connect to ", peripheral)
        if let error {
            self.error = .connectFailure(error.localizedDescription)
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        timestamp: CFAbsoluteTime,
        isReconnecting: Bool,
        error: (any Error)?
    ) {
        print("peripheral disconnected: ", peripheral)
    }

}  // CBCentralManagerDelegate extension

extension MidiPeripheral: CBPeripheralDelegate {
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: (any Error)?
    ) {
        print("service discovered for peripheral:", peripheral)
        if let error {
            self.error = .serviceDiscoveryFailure(error.localizedDescription)
            return
        }

        for service in peripheral.services ?? [] {
            if service.uuid == MidiIdentifiers.gapService {
                peripheral.discoverCharacteristics(
                    [MidiIdentifiers.deviceNameCharacteristic],
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
            self.error = .includedServiceDiscoveryFailure(
                error.localizedDescription
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
            if characteristic.uuid == MidiIdentifiers.deviceNameCharacteristic {
                peripheral.readValue(for: characteristic)
            }
        }

        if let error {
            self.error = .characteristicDiscoveryFailure(
                error.localizedDescription
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
            self.error = .descriptorDiscoveryFailure(error.localizedDescription)
            return
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        if let error {
            self.error = .notificationFailure(error.localizedDescription)
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
            self.error = .writeError(error.localizedDescription)
            return
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: (any Error)?
    ) {
        print("didUpdateValueFor characteristic", characteristic)

        if let error {
            self.error = .characteristicUpdateFailure(
                error.localizedDescription
            )
            return
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor descriptor: CBDescriptor,
        error: (any Error)?
    ) {
        print("didUpdateValueFor descriptor", descriptor)
        if let error {
            self.error = .descriptorDiscoveryFailure(error.localizedDescription)
            return
        }
    }

}  // CBPeripheralDelegate extension
