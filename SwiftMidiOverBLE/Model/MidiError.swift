//
//  MidiPeripheralError.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 20/07/2025.
//

import Foundation

enum MidiError: Error {
    // Peripheral role
    case invalidManager
    case invalidCharacteristic
    case invalidService
    case bluetoothNotAvailable
    case addServiceError(String)
    case removeServiceError(String)
    case startAdvertisingError(String)
    case updateValueError(String)
    case invalidCentral(String)
    case invalidPacket(String)
    case invalidStatus(String)
    case bufferFailure(String)
    case unsupportedFeature(String)
    
    // Central role
    case invalidPeripheral
    case connectFailure(String)
    case disconnectFailure(String)
    case serviceDiscoveryFailure(String)
    case includedServiceDiscoveryFailure(String)
    case characteristicDiscoveryFailure(String)
    case descriptorDiscoveryFailure(String)
    case notificationFailure(String)
    case characteristicUpdateFailure(String)
    
    case readError(String)
    case writeError(String)
    
    case decodeFailure(String)
}
