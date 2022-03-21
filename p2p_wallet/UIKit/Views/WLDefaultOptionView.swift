//
//  WLDefaultOptionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/09/2021.
//

import Foundation

class WLDefaultOptionView: BEView, OptionViewType {
    lazy var label = UILabel(text: nil)

    private lazy var radioButton: WLRadioButton = {
        let checkBox = WLRadioButton()
        checkBox.isUserInteractionEnabled = false
        return checkBox
    }()

    override func commonInit() {
        super.commonInit()
        let stackView = UIStackView(
            axis: .horizontal,
            spacing: 16,
            alignment: .center,
            distribution: .fill,
            arrangedSubviews: [
                radioButton, label,
            ]
        )
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 0, y: 20))
    }

    func setSelected(_ selected: Bool) {
        radioButton.isSelected = selected
    }
}
