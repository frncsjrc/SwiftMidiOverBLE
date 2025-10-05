//
//  EditMessageMask.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 30/08/2025.
//

import SwiftUI

struct EditMessageMask: View {
    @Binding var mask: MessageMask

    var allowRanges: Bool = true
    
    var dataCount: Int {
        mask.type.dataHeaders.count
    }

    var body: some View {
        Form {
            Section(header: Text("Type")) {
                Picker("", selection: $mask.type) {
                    ForEach(MessageType.allCases, id: \.self) { type in
                        Text(String(describing: type))
                    }
                }
            }

            if mask.type.status < 0xF0 {
                Section(header: Text("Channel")) {
                    if allowRanges {
                        
                    } else {
                        
                    }
                }
            }
            
            ForEach(0..<dataCount, id: \.self) { i in
                Section(header: Text(mask.type.dataHeaders[i])) {
                    Text("\(i)")
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var mask = MessageMask(type: .noteOn)

    EditMessageMask(mask: $mask)
}
