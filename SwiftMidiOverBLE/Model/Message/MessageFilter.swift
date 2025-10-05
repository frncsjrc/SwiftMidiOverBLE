//
//  MessageFilter.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 17/08/2025.
//

import Foundation

class MessageFilter {
    enum Role: String {
        case preserve
        case discard
    }

    var role: Role
    var masks: [MessageMask]

    init(role: Role = .discard, masks: [MessageMask] = []) {
        self.role = role
        self.masks = masks
    }

    func matches(_ message: Message) -> Bool {
        return masks.first(where: { $0.matches(message) }) != nil
    }

    func preserve(_ message: Message) -> Bool {
        return
            (role == .preserve
            && masks.first(where: { $0.matches(message) }) != nil)
            || (role == .discard && masks.allSatisfy({ !$0.matches(message) }))
    }

    func discard(_ message: Message) -> Bool {
        return !preserve(message)
    }
}
