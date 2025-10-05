//
//  RangePicker.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 30/08/2025.
//

import SwiftUI

struct RangePicker: View {
    enum RangeType: Int, CaseIterable {
        case any
        case exact
        case maximum
        case minimum
        case range

        var label: String {
            switch self {
            case .any:
                return String(
                    localized: "Any value",
                    comment:
                        "Label in the range picker view when the user wants to select any value"
                )
            case .exact:
                return String(
                    localized: "Exactly",
                    comment:
                        "Label in the range picker view when the user wants to select a specific value"
                )
            case .maximum:
                return String(
                    localized: "At most",
                    comment:
                        "Label in the range picker view when the user wants to select values up to a maximum"
                )
            case .minimum:
                return String(
                    localized: "At least",
                    comment:
                        "Label in the range picker view when the user wants to select values starting from a minimum"
                )
            case .range:
                return String(
                    localized: "Range",
                    comment:
                        "Label in the range picker view when the user wants to select a range"
                )
            }
        }
    }

    @Binding var range: MessageMask.Bounds?
    var minimumValue: UInt8 = 0
    var maximumValue: UInt8 = 127

    var allowRange: Bool

    @State private var rangeType: RangeType
    @State private var lowerBound: UInt8
    @State private var upperBound: UInt8
    
    private var values: [UInt8] {
        Array(minimumValue...maximumValue)
    }

    init(
        range: Binding<MessageMask.Bounds?>,
        minimumValue: UInt8,
        maximumValue: UInt8,
        allowRange: Bool
    ) {
        self._range = range
        self.minimumValue = minimumValue
        self.maximumValue = maximumValue
        self.allowRange = allowRange

        guard allowRange else {
            self.rangeType = .exact
            if let lower = range.wrappedValue?.lower {
                let bound = max(
                    min(lower, maximumValue),
                    minimumValue
                )
                self.lowerBound = bound
                self.upperBound = bound
                return
            }
            if let upper = range.wrappedValue?.upper {
                let bound = max(
                    min(upper, maximumValue),
                    minimumValue
                )
                self.lowerBound = bound
                self.upperBound = bound
                return
            }
            self.lowerBound = minimumValue
            self.upperBound = minimumValue
            return
        }

        if let bounds = range.wrappedValue {
            if let lower = bounds.lower {
                self.lowerBound = max(
                    min(lower, maximumValue),
                    minimumValue
                )
                if let upper = bounds.upper {
                    self.upperBound = max(
                        min(upper, maximumValue),
                        minimumValue
                    )
                    self.rangeType = lower == upper ? .exact : .range
                } else {
                    self.upperBound = maximumValue
                    self.rangeType = .minimum
                }
            } else {
                self.lowerBound = minimumValue
                if let upper = bounds.upper {
                    self.upperBound = max(
                        min(upper, maximumValue),
                        minimumValue
                    )
                    self.rangeType = .maximum
                } else {
                    self.upperBound = maximumValue
                    self.rangeType = .any
                }
            }
        } else {
            self.lowerBound = minimumValue
            self.upperBound = maximumValue
            self.rangeType = .any
        }
    }

    var body: some View {
        HStack {
            if allowRange {
                Picker("", selection: $rangeType) {
                    ForEach(RangeType.allCases, id: \.self) { type in
                        Text(type.label)
                    }
                    .frame(width: 200)
                }
            }
            if rangeType != .any {
                ValuePicker(
                    pickedValue: $lowerBound,
                    minValue: minimumValue,
                    maxValue: maximumValue
                )
                .onChange(of: lowerBound) {
                    if lowerBound > upperBound {
                        upperBound = lowerBound
                    }
                }
            }
            if rangeType == .range {
                ValuePicker(
                    pickedValue: $upperBound,
                    minValue: minimumValue,
                    maxValue: maximumValue
                )
                .onChange(of: upperBound) {
                    if upperBound < lowerBound {
                        lowerBound = upperBound
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview("Fixed value") {
    @Previewable @State var range: MessageMask.Bounds? = nil

    RangePicker(
        range: $range,
        minimumValue: 12,
        maximumValue: 107,
        allowRange: false
    )
}

#Preview("Any value") {
    @Previewable @State var range: MessageMask.Bounds? = nil

    RangePicker(
        range: $range,
        minimumValue: 12,
        maximumValue: 107,
        allowRange: true
    )
}

#Preview("Exact") {
    @Previewable @State var range: MessageMask.Bounds? = (lower: 31, upper: 31)

    RangePicker(
        range: $range,
        minimumValue: 12,
        maximumValue: 107,
        allowRange: true
    )
}

#Preview("Range") {
    @Previewable @State var range: MessageMask.Bounds? = (lower: 7, upper: 83)

    RangePicker(
        range: $range,
        minimumValue: 3,
        maximumValue: 107,
        allowRange: true
    )
}
