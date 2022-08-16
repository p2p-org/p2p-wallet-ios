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
        UIHostingControllerWithoutNavigation(rootView: self)
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

// MARK: - Swipe

extension View {
    func swipeActions(
        leading: [SwipeActionButton] = [],
        allowsFullSwipeLeading: Bool = false,
        trailing: [SwipeActionButton] = [],
        allowsFullSwipeTrailing: Bool = false
    ) -> some View {
        modifier(SwipeActionView(
            leading: leading,
            allowsFullSwipeLeading: allowsFullSwipeLeading,
            trailing: trailing,
            allowsFullSwipeTrailing: allowsFullSwipeTrailing
        ))
    }
}

extension List {
    @ViewBuilder func withoutSeparatorsiOS14() -> some View {
        if #available(iOS 15, *) {
            self
        } else {
            listStyle(SidebarListStyle())
                .listRowInsets(EdgeInsets())
                .onAppear {
                    UITableView.appearance().backgroundColor = UIColor.systemBackground
                }
        }
    }
}

extension View {
    @ViewBuilder func withoutSeparatorsAfterListContent() -> some View {
        if #available(iOS 15, *) {
            listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
        } else {
            frame(
                minWidth: 0, maxWidth: .infinity,
                minHeight: 44,
                alignment: .leading
            )
                .listRowInsets(EdgeInsets())
                .background(Color(UIColor.systemBackground))
        }
    }
}
