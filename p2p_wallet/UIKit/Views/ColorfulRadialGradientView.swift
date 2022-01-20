//
//  ColorfulRadialGradientView.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 19.01.2022.
//

import UIKit

final class ColorfulRadialGradientView: UIView {
    override func draw(_ rect: CGRect) {
        let colors = [UIColor.e7f959, .h59bf82, .h4d84e8, .h4c76ff].map(\.cgColor) as CFArray

        guard let gradient = CGGradient(colorsSpace: nil, colors: colors, locations: nil) else { return }

        UIGraphicsGetCurrentContext()?.drawRadialGradient(
            gradient,
            startCenter: .zero,
            startRadius: 0,
            endCenter: .zero,
            endRadius: rect.width / 2,
            options: .drawsAfterEndLocation
        )
    }
}
