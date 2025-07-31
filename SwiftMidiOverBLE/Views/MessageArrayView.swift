//
//  MessageArrayView.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 25/07/2025.
//

import SwiftUI

struct MessageArrayView: View {
    var messages: [MidiMessage] = []

    var body: some View {
        VStack {
            let messageCount = messages.count
            if messageCount < 1 {
                HStack {
                    Text("No Messages")
                        .font(.system(size: 12))
                        .italic()
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                }
            } else {
                let firstIndex = max(0, messageCount - 6)
                ForEach(
                    Array(
                        (firstIndex..<messageCount).reversed()
                    ),
                    id: \.self
                ) { index in
                    HStack {
                        Text(messages[index].toStringWithLocalStamp)
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                    }
                }
            }
        }
        .padding(.leading)
    }
}

#Preview {
    MessageArrayView(messages: MidiMessage.samples1)
}
