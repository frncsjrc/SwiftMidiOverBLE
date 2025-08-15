//
//  DeviceGeometryModifier.swift
//  SwiftMidiOverBLE
//
//  Created by François Jean Raymond CLÉMENT on 02/08/2025.
//
//  Based upon Heydays Jazz's work at https://medium.com/@heydays.jazz_06/swiftui-size-and-orientation-matters-df1356b5fdbb
//

import SwiftUI

struct DeviceGeometryModifier: ViewModifier {
    let deviceGeometry: Binding<DeviceGeometry>

    func body(content: Content) -> some View {
        content.background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: DeviceGeometryPreferenceKey.self,
                    value: DeviceGeometry(size: proxy.size)
                )
            }
            .onPreferenceChange(DeviceGeometryPreferenceKey.self) { (value) in
                self.deviceGeometry.wrappedValue = value
            }
        }
    }
}

struct DeviceGeometry: Identifiable, Equatable {
    let size: CGSize
    var id: String { "\(size.width):\(size.height)" }
    var isPortrait: Bool { size.width < size.height }

    static let empty = DeviceGeometry(size: .zero)

    static func == (lhs: DeviceGeometry, rhs: DeviceGeometry) -> Bool {
        return lhs.id == rhs.id
    }
}

struct DeviceGeometryPreferenceKey: PreferenceKey {
    typealias Value = DeviceGeometry
    static var defaultValue: DeviceGeometry = .empty

    static func reduce(
        value: inout DeviceGeometry,
        nextValue: () -> DeviceGeometry
    ) {
        value = nextValue()
    }
}

struct DeviceGeometryEnvironmentKey: EnvironmentKey {
    static let defaultValue: DeviceGeometry = .empty
}

extension EnvironmentValues {
    var deviceGeometry: DeviceGeometry {
        get { self[DeviceGeometryEnvironmentKey.self] }
        set { self[DeviceGeometryEnvironmentKey.self] = newValue }
    }
}

extension View {
    func updateDeviceGeometry(_ deviceGeometry: Binding<DeviceGeometry>)
        -> some View
    {
        return modifier(DeviceGeometryModifier(deviceGeometry: deviceGeometry))
    }
}
