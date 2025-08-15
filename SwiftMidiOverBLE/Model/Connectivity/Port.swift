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
            return Group {
                Image(systemName: "ipad.landscape.and.iphone")
                Image(systemName: "p.square")
            }
        case .localCentral:
            return Group {
                Image(systemName: "ipad.landscape.and.iphone")
                Image(systemName: "c.square")
            }
        case .bluetoothMidiPeripheral:
            return Group {
                Image(systemName: "antenna.radiowaves.left.and.right")
                Image(systemName: "p.square")
            }
        case .bluetoothMidiCentral:
            return Group {
                Image(systemName: "antenna.radiowaves.left.and.right")
                Image(systemName: "c.square")
            }
        }
    }
}
