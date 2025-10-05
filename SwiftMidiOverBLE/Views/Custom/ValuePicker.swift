//
//  ValuePicker.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 30/08/2025.
//

import SwiftUI

struct ValuePicker: View {
    @Binding var pickedValue: UInt8
    private var minValue: UInt8
    private var maxValue: UInt8
    private var valueCount: Int
    private var minWheelTarget: Int
    private var maxWheelTarget: Int
    private var maxWheelValue: Int
    @State private var wheelValue: Int

    private var allowedValues: [Int] { Array(Int(minValue)...Int(maxValue)) }

    private func label(_ wheelValue: Int) -> String {
        let value = UInt8(wheelValue % valueCount) + minValue
        return String(value)
    }

    init(
        pickedValue: Binding<UInt8>,
        minValue: UInt8 = 0,
        maxValue: UInt8 = 127
    ) {
        self._pickedValue = pickedValue
        self.minValue = minValue
        self.maxValue = maxValue
        self.valueCount = Int(maxValue - minValue) + 1
        self.minWheelTarget = valueCount
        self.maxWheelTarget = valueCount * 2 - 1
        self.maxWheelValue = valueCount * 3 - 1
        self.wheelValue = Int(pickedValue.wrappedValue - minValue) + valueCount
    }

    var body: some View {
        VStack {
            Picker("", selection: $wheelValue) {
                ForEach(Array(0...maxWheelValue), id: \.self) { value in
                    Text(label(value))
                        .font(.body)
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80)
            .onChange(of: pickedValue) {
                wheelValue = Int($pickedValue.wrappedValue - minValue) + valueCount
            }
            .onChange(of: wheelValue) {
                if wheelValue < minWheelTarget {
                    wheelValue += valueCount
                } else if wheelValue > maxWheelTarget {
                    wheelValue -= valueCount
                }
                pickedValue = UInt8(wheelValue - valueCount) + minValue
            }
        }
        .frame(height: 100)
    }
}

#Preview("Default") {
    ValuePicker(
        pickedValue: .constant(64)
    )
}

#Preview("With Bounded Values") {
    ValuePicker(
        pickedValue: .constant(64),
        minValue: 17,
        maxValue: 31
    )
}
