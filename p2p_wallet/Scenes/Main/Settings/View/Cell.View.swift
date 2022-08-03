//  Cell.View.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 11.01.22.
//
//

import UIKit

extension Settings {
    class CellView: BECompositionView {
        let icon: UIImage
        let title: UIView
        let trailing: UIView?
        let dividerEnable: Bool
        let nextArrowEnable: Bool

        init(
            icon: UIImage,
            title: UIView,
            trailing: UIView? = nil,
            dividerEnable: Bool = true,
            nextArrowEnable: Bool = true
        ) {
            self.icon = icon
            self.title = title
            self.trailing = trailing
            self.dividerEnable = dividerEnable
            self.nextArrowEnable = nextArrowEnable
            super.init()
        }

        override func build() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                UIStackView(axis: .horizontal, alignment: .center) {
                    UIImageView(width: 24, height: 24, image: icon)
                        .padding(.init(only: .right, inset: 8))
                    title
                    UIView.spacer
                    if trailing != nil { trailing! }
                    if nextArrowEnable { UIView.defaultNextArrow().padding(.init(only: .left, inset: 16)) }
                }.padding(.init(x: 18, y: 0))
                if dividerEnable { UIView.defaultSeparator().padding(.init(only: .left, inset: 50)) }
            }.frame(height: 61)
        }
    }
}
