//
//  Binding+OptionalIsPresent.swift
//  DiscoScan
//

import SwiftUI

extension Binding where Value == String? {
    /// Drives alert/sheet presentation from optional message state without closure bindings in views.
    var isNonNil: Binding<Bool> {
        Binding<Bool>(
            get: { wrappedValue != nil },
            set: { (isPresented: Bool) in
                if !isPresented {
                    wrappedValue = nil
                }
            }
        )
    }
}
