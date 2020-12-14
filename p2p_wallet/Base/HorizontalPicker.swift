//
//  HorizontalPicker.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/12/2020.
//

import Foundation

class HorizontalPicker: BEView {
    private lazy var stackView = UIStackView(axis: .horizontal, spacing: 0, alignment: .fill, distribution: .fillEqually)
    
    var labels: [String] = [] {
        didSet {
            stackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
            stackView.addArrangedSubviews(labels.map {UILabel(text: $0, textSize: 15, textColor: .secondary, textAlignment: .center)})
        }
    }
    
    var selectedIndex: Int = -1 {
        didSet {
            guard selectedIndex > 0 && selectedIndex < labels.count else {return}
            for (index, label) in (stackView.arrangedSubviews as! [UILabel]).enumerated() {
                if index != selectedIndex {
                    label.textColor = .secondary
                    label.font = .systemFont(ofSize: 15)
                } else {
                    label.textColor = .textBlack
                    label.font = .systemFont(ofSize: 15, weight: .bold)
                }
            }
        }
    }
    
    override func commonInit() {
        super.commonInit()
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
    }
}
