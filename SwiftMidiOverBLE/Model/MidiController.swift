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

class MidiController: NSObject {
    static let shared = MidiController()
    
    private let MidiServiceUUID = CBUUID(
        string: "03B80E5A-EDE8-4B33-A751-6CE34EC4C700"
    )
    private let MidiDataUUID = CBUUID(
        string: "7772E5DB-3868-4112-A1A9-F2669D106BF3"
    )
    private let advertizedName = "Drum2Light Test"
    private let advertizedManufacturer = "François Jean Raymond CLÉMENT"
    
    private var peripheralBluetoothManager: CBPeripheralManager
    //    var centralBluetoothManager: CBCentralManager
    //    var peripherals: [CBPeripheral] = []
    
    var advertise: Bool
    
    init(
        peripheralBluetoothManager: CBPeripheralManager = CBPeripheralManager(),
        advertise: Bool = false
    ) {
        self.peripheralBluetoothManager = peripheralBluetoothManager
        self.advertise = advertise
        super.init()
        updateAdvertise()
    }
    
    func updateAdvertise() {
        if advertise {
            advertiseBluetoothService()
        } else {
            peripheralBluetoothManager.stopAdvertising()
        }
    }
}

extension MidiController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Powered On")
            let mutableService = CBMutableService(
                type: MidiServiceUUID,
                primary: true
            )
            let mutableCharacteristic = CBMutableCharacteristic(
                type: MidiDataUUID,
                properties: [.writeWithoutResponse, .read, .notify],
                value: nil,
                permissions: [.readable, .writeable]
            )
            mutableService.characteristics = [mutableCharacteristic]
            peripheralBluetoothManager.add(mutableService)
            advertiseBluetoothService()
        case .poweredOff:
            print("Powereed Off")
        case .resetting:
            print("Resetting")
        case .unauthorized:
            print("Unauthorized")
        case .unknown:
            print("Unknown")
        case .unsupported:
            print("Unsupported")
        default:
            print(peripheral.state)
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        willRestoreState dict: [String: Any]
    ) {
        peripheral.delegate = self
        self.peripheralBluetoothManager = peripheral
        if !peripheral.isAdvertising {
            advertiseBluetoothService()
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didStartAdvertising error: Error?
    ) {
        print("Did start advertising")
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveRead request: CBATTRequest
    ) {
        let data: [UInt8] = [127, 127]  // TODO: manage read data
        let value: Data = Data(data)
        request.value = value
        peripheralBluetoothManager.respond(to: request, withResult: .success)
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveWrite requests: [CBATTRequest]
    ) {
        if let request = requests.first {
            if let value = request.value {
                let valueBytes: [UInt8] = [UInt8](value)
                print("MIDI: \(valueBytes)")
            }
        }
    }
    
    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        print(
            "Central \(central.description) did subscribe to \(characteristic)"
        )
    }

    private func advertiseBluetoothService() {
        peripheralBluetoothManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [MidiServiceUUID],
            CBAdvertisementDataLocalNameKey: advertizedName,
            //            CBAdvertisementDataManufacturerDataKey: advertizedManufacturer,
        ])
    }
}
