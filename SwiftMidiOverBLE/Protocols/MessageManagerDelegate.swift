//
//  MessageManagerDelegate.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 09/08/2025.
//

import Foundation
import CoreBluetooth

protocol MessageManagerDelegate {
    func process(incoming messages: [Message])
}
