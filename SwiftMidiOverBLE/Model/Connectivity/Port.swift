//
//  Port.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 10/08/2025.
//

import Foundation
import SwiftUI

enum Port: Int {
    case localPeripheral
    case localCentral
    case bluetoothMidiPeripheral
    case bluetoothMidiCentral

    var icon: some View {
            switch self {
            case .localPeripheral:
                Image(systemName: "p.square")
            case .localCentral:
                Image(systemName: "c.square")
            case .bluetoothMidiPeripheral:
                Image(systemName: "p.square")
            case .bluetoothMidiCentral:
                Image(systemName: "c.square")
            }
    }
}
