//
//  UIView+Builders.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/11/2021.
//

import BEPureLayout
import KeyAppUI
import SwiftUI
import UIKit

extension UIView {
    /// Grey banner
    static func greyBannerView(
        contentInset: UIEdgeInsets = .init(all: 18),
        axis: NSLayoutConstraint.Axis = .vertical,
        spacing: CGFloat = 8,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill,
        @BEStackViewBuilder builder: () -> [BEStackViewElement]
    ) -> UIView {
        UIStackView(axis: axis, spacing: spacing, alignment: alignment, distribution: distribution, builder: builder)
            .padding(contentInset, backgroundColor: .a3a5ba.withAlphaComponent(0.05), cornerRadius: 12)
    }

    static func defaultSeparator(height: CGFloat = 1) -> UIView {
        .separator(height: height, color: .separator)
    }
}
