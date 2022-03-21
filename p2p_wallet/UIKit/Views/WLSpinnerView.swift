//
//  WLSpinnerView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/07/2021.
//

import Foundation

class WLSpinnerView: BESpinnerView {
    override init(size: CGFloat, endColor: UIColor = .black) {
        super.init(size: size, endColor: endColor)
        let padding: CGFloat = 10
        let imageView = UIImageView(
            width: size - 2 * padding,
            height: size - 2 * padding,
            cornerRadius: (size - 2 * padding) / 2,
            image: .spinnerIcon
        )
        addSubview(imageView)
        imageView.autoCenterInSuperview()
    }
}
