//
//  WLRadioButton.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/03/2021.
//

import Foundation

class WLRadioButton: BEView {
    init() {
        super.init(frame: .zero)
    }

    override func commonInit() {
        super.commonInit()
        autoSetDimensions(to: .init(width: 20, height: 20))
        layer.cornerRadius = 10
        layer.masksToBounds = true
        isSelected = false
    }

    var isSelected: Bool = false {
        didSet {
            resetBorder()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        resetBorder()
    }

    private func resetBorder() {
        border(width: isSelected ? 6 : 2, color: isSelected ? .h5887ff : .a3a5ba)
    }
}
