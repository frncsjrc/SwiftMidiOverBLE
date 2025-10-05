//
//  RemotePseudos.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 30/08/2025.
//

import Foundation

class RemoteManager {
    static let shared = RemoteManager()
    
    var pseudos: [UUID: String] = [:]
    
    private init() {}
    
    func remoteName(for remote: UUID, on central: Central) -> String {
        if let name = pseudos[remote], !name.isEmpty {
            return name
        }
        
        if let details = central.remotePeripherals[remote], !details.name.isEmpty {
            return details.name
        }
        
        return Constants.unknownRemoteName
    }
    
    func remoteName(for remote: UUID, on peripheral: Peripheral) -> String {
        if let name = pseudos[remote], !name.isEmpty {
            return name
        }
        
        if let details = peripheral.remoteCentrals[remote], !details.name.isEmpty {
            return details.name
        }
        
        return Constants.unknownRemoteName
    }
}
