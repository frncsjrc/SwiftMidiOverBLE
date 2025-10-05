//
//  MessageArrayView.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 25/07/2025.
//

import SwiftUI

struct IncomingView: View {
    var messages: [Message] = []

    var body: some View {
        ScrollView {
            let messageCount = messages.count
            if messageCount < 1 {
                HStack {
                    Text(String(localized: "No Messages", comment: "Warn no messages have been received"))
                        .font(.system(size: 12))
                        .italic()
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                }
            } else {
                //                let firstIndex = max(0, messageCount - 6)
                ForEach(
                    Array(
                        (0..<messageCount).reversed()
                    ),
                    id: \.self
                ) { index in
                    HStack {
                        messages[index].portIcon
                        Text(
                            messages[index].toStringWithSourceNameAndLocalStamp
                        )
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview("Populated") {
    IncomingView(messages: Message.samples2)
}

#Preview("Empty") {
    IncomingView(messages: [])
}
