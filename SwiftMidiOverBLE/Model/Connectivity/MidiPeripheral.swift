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

    private var midiService: CBMutableService?
    private var midiCharacteristic: CBMutableCharacteristic?
    private var midiData: Data = Data()

    private var subscribedCentrals: Set<CBCentral> = []

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
    
    @MainActor
    func setSubscriberName(_ name: String, for central: UUID) {
        remoteCentrals[central]?.name = name
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
            type: Constants.midiService,
            primary: true,
        )

        guard let midiService else {
            self.error = .invalidService
            return
        }

        midiCharacteristic = CBMutableCharacteristic(
            type: Constants.midiDataCharacteristic,
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
                    Constants.midiService
                ],
                CBAdvertisementDataLocalNameKey: peripheralName,
            ])
        } else if !advertize && peripheralManager!.isAdvertising {
            print("about to stop advertising")
            peripheralManager!.stopAdvertising()
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
                    self.subscribedCentrals.insert($0)
                    let remoteName = MidiCentral.shared.requestRemoteName(for: $0.identifier)
                    self.remoteCentrals[$0.identifier]? = RemoteDetails(
                        name: remoteName,
                        state: .connected
                    )
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
        print("did start advertising with error: \(String(describing: error))")
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
            if currentName != nil && currentName != Constants.unknownRemoteName {
                self.remoteCentrals[central.identifier]?.state = .connected
            } else {
                let remoteName = MidiCentral.shared.requestRemoteName(for: central.identifier)
                self.remoteCentrals[central.identifier] = RemoteDetails(
                    name: remoteName,
                    state: .connected
                )
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
