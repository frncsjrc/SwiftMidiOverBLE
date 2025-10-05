//
//  RemoteDetails.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 15/08/2025.
//

import Foundation

struct RemoteDetails {
    var name: String
    var enable: Bool = true
    var state: RemoteState = .offline
    var manufacturer: String? = nil
    var model: String? = nil
}
