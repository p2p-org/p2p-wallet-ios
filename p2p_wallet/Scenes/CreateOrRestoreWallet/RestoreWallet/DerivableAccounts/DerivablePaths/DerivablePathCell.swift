//
//  DerivablePathCell.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/05/2021.
//

import Foundation
import BECollectionView

class DerivablePathCell: BaseCollectionViewCell, BECollectionViewCell {
    private lazy var radioButton = WLRadioButton()
    private lazy var titleLabel = UILabel(textSize: 17, numberOfLines: 0)
    
    lazy var stackView = UIStackView(axis: .horizontal, spacing: 20, alignment: .center, distribution: .fill) {
        radioButton
        titleLabel
    }
    
    override func commonInit() {
        super.commonInit()
        
        contentView.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(all: 22))
    }
    
    func setUp(with item: AnyHashable?) {
        guard let path = item as? SelectableDerivablePath else {return}
        radioButton.isSelected = path.isSelected
        var pathTitle = path.path.rawValue
        if path.path.type == .deprecated {
            pathTitle += " (\(L10n.deprecated))"
        }
        titleLabel.text = pathTitle
    }
    
    func showLoading() {
        stackView.hideLoader()
        stackView.showLoader()
    }
    func hideLoading() {
        stackView.hideLoader()
    }
}
