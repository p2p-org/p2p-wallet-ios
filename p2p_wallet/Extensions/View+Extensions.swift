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

    func uiView() -> UIView {
        asViewController().view
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

// MARK: - Font

private struct TextModifier: ViewModifier {
    let uiFont: UIFont

    func body(content: Content) -> some View {
        content.font(SwiftUI.Font(uiFont: uiFont))
    }
}

extension View {
    func font(uiFont: UIFont) -> some View {
        modifier(TextModifier(uiFont: uiFont))
    }
}
