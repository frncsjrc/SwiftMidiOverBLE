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
class MidiPeripheral: NSObject {
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
    
    private var timeManager: MidiTimeManager = MidiTimeManager.shared

    private var midiService: CBMutableService?
    private var midiCharacteristic: CBMutableCharacteristic?
    private var midiData: Data = Data()

    var advertize: Bool = false

    private(set) var subscribedCentrals: [CBCentral: MidiDefinitions.ReceivedData] = [:]

    override init() {
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
    }
}

extension MidiPeripheral {

    static func currentTime() -> UInt64 {
        clock_gettime_nsec_np(CLOCK_MONOTONIC)
    }

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
            type: MidiDefinitions.serviceUUID,
            primary: true,
        )

        guard let midiService else {
            self.error = .invalidService
            return
        }

        midiCharacteristic = CBMutableCharacteristic(
            type: MidiDefinitions.characteristicUUID,
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
    func updateAdvertising() {
        addMidiServiceIfNeeded()

        if !checkPeripheral() {
            return
        }

        if self.advertize && !peripheralManager!.isAdvertising {
            print("about to start advertising")
            peripheralManager!.startAdvertising([
                CBAdvertisementDataServiceUUIDsKey: [MidiDefinitions.serviceUUID],
                CBAdvertisementDataLocalNameKey: peripheralName,
            ])
        } else if !self.advertize && peripheralManager!.isAdvertising {
            print("about to stop advertising")
            peripheralManager!.stopAdvertising()
        }
    }

    @MainActor
    func updateValue(
        _ data: Data,
        withSubscribedCentrals subscribedCentrals: [CBCentral]
    ) {
        do {
            try updateValueHelper(data, subscribedCentrals)
        } catch (let error) {
            if let error = error as? MidiError {
                self.error = error
            }
        }
    }

    @MainActor
    private func updateValueHelper(
        _ data: Data,
        _ subscribedCentrals: [CBCentral]
    ) throws {
        if !checkPeripheral() {
            return
        }

        let mtu =
            subscribedCentrals.isEmpty
            ? 512
            : subscribedCentrals.map({ $0.maximumUpdateValueLength }).min()
                ?? 512
        if data.count > mtu {
            throw MidiError.updateValueError("Data is too long.")
        }

        // true if data size is compatible with MTU,
        let result = peripheralManager!.updateValue(
            data,
            for: midiCharacteristic!,
            onSubscribedCentrals: subscribedCentrals
        )

        if result {
            self.midiData.insert(contentsOf: data, at: 0)
        } else {
            self.error = .updateValueError(
                "Failed to update value. Transmit queue is full. Please try again later."
            )
        }
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
                    self.subscribedCentrals[$0] = MidiDefinitions.ReceivedData()
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
            self.subscribedCentrals[central] = MidiDefinitions.ReceivedData()
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        DispatchQueue.main.async { self.subscribedCentrals.removeValue(forKey: central) }
    }

    // invoked when Central made a read request
    // to have central receive the value of the characteristic, need to be set using request.value
    // otherwise, central will not receive any update on the value of the characteristic in peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?)
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

    // invoked when Central made a write request
    // handle the request (update the value)
    // respond using respondToRequest:withResult:
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
            if var requestValue: Data = request.value {
                requestValue = requestValue.dropFirst(request.offset)
                print("processing write request from central \(request.central.identifier.uuidString)")
                decodePacket(request.central, requestValue)
            }
        }
    }

    private func decodePacket(_ requester: CBCentral, _ packet: Data) {
        guard let messageBuffers = subscribedCentrals[requester] else {
            self.error = .invalidCentral(
                "Can't decode packet for unknown central"
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
            subscribedCentrals[requester]!.pendingSystemExclusiveMessage =
                pendingSystemExclusiveMessage
            decodedMessages.forEach {
                subscribedCentrals[requester]!.messages.append($0)
            }
        } else {
            subscribedCentrals[requester]!.pendingSystemExclusiveMessage = nil
        }
    }

    func send(_ message: MidiMessage, to centrals: [CBCentral] = []) {
        if !checkPeripheral() {
            return
        }

        let targets: [CBCentral] =
            centrals.isEmpty ? Array(subscribedCentrals.keys) : centrals

        let mtu = targets.map({ $0.maximumUpdateValueLength }).min() ?? 256

        let packets: [Data] = message.encodePackets(timeManager, mtu)

        packets.forEach {
            peripheralManager!.updateValue(
                $0,
                for: midiCharacteristic!,
                onSubscribedCentrals: targets
            )
        }
    }
}
