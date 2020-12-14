//
//  HorizontalPicker.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/12/2020.
//

import Foundation

protocol HorizontalPickerDelegate: class {
    func picker(_ picker: HorizontalPicker, didSelectOptionAtIndex index: Int)
}
class HorizontalPicker: BEView {
    private class GestureRegconizer: UITapGestureRecognizer {
        var index: Int?
    }
    
    private lazy var stackView = UIStackView(axis: .horizontal, spacing: 0, alignment: .fill, distribution: .fillEqually)
    weak var delegate: HorizontalPickerDelegate?
    
    var labels: [String] = [] {
        didSet {
            stackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
            stackView.addArrangedSubviews(labels.enumerated().map {
                let label = UILabel(text: $1, textSize: 15, textColor: .secondary, textAlignment: .center)
                let gesture = GestureRegconizer(target: self, action: #selector(buttonOptionDidTouch(_:)))
                gesture.index = $0
                label.addGestureRecognizer(gesture)
                label.isUserInteractionEnabled = true
                return label
            })
        }
    }
    
    var selectedIndex: Int = -1 {
        didSet {
            guard selectedIndex >= 0 && selectedIndex < labels.count else {return}
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
    
    @objc private func buttonOptionDidTouch(_ gesture: UIGestureRecognizer) {
        let index = (gesture as! GestureRegconizer).index!
        selectedIndex = index
        delegate?.picker(self, didSelectOptionAtIndex: index)
    }
}
