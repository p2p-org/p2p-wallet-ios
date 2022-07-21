//
//  View+Extensions.swift
//  p2p_wallet
//
//  Created by Ivan on 14.06.2022.
//

import Combine
import SwiftUI

extension View {
    func asViewController() -> UIViewController {
        UIHostingController(rootView: self)
    }

    /// A backwards compatible wrapper for iOS 14 `onChange`
    @ViewBuilder func valueChanged<T: Equatable>(value: T, onChange: @escaping (T) -> Void) -> some View {
        if #available(iOS 14.0, *) {
            self.onChange(of: value, perform: onChange)
        } else {
            onReceive(Just(value)) { value in
                onChange(value)
            }
        }
    }
}
