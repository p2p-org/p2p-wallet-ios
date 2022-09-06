//
//  View+Extensions.swift
//  p2p_wallet
//
//  Created by Ivan on 14.06.2022.
//

import Combine
import SwiftUI

extension View {
    func asViewController(withoutUIKitNavBar: Bool = true) -> UIViewController {
        withoutUIKitNavBar
            ? UIHostingControllerWithoutNavigation(rootView: self)
            : UIHostingController(rootView: self)
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

extension Text {
    init(_ astring: NSAttributedString) {
        self.init("")

        astring.enumerateAttributes(in: NSRange(location: 0, length: astring.length), options: []) { attrs, range, _ in

            var t = Text(astring.attributedSubstring(from: range).string)

            if let color = attrs[NSAttributedString.Key.foregroundColor] as? UIColor {
                t = t.foregroundColor(Color(color))
            }

            if let font = attrs[NSAttributedString.Key.font] as? UIFont {
                t = t.font(.init(font))
            }

            if let kern = attrs[NSAttributedString.Key.kern] as? CGFloat {
                t = t.kerning(kern)
            }

            if let striked = attrs[NSAttributedString.Key.strikethroughStyle] as? NSNumber, striked != 0 {
                if let strikeColor = (attrs[NSAttributedString.Key.strikethroughColor] as? UIColor) {
                    t = t.strikethrough(true, color: Color(strikeColor))
                } else {
                    t = t.strikethrough(true)
                }
            }

            if let baseline = attrs[NSAttributedString.Key.baselineOffset] as? NSNumber {
                t = t.baselineOffset(CGFloat(baseline.floatValue))
            }

            if let underline = attrs[NSAttributedString.Key.underlineStyle] as? NSNumber, underline != 0 {
                if let underlineColor = (attrs[NSAttributedString.Key.underlineColor] as? UIColor) {
                    t = t.underline(true, color: Color(underlineColor))
                } else {
                    t = t.underline(true)
                }
            }

            self = self + t
        }
    }
}
