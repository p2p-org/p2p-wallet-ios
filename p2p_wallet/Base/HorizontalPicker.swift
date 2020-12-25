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
    
    private lazy var stackView = UIStackView(axis: .horizontal, spacing: 0, alignment: .fill, distribution: .equalSpacing)
    weak var delegate: HorizontalPickerDelegate?
    
    var labels: [String] = [] {
        didSet {
            stackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
            stackView.addArrangedSubviews(labels.enumerated().map {
                let label = UILabel(text: $1, textSize: 15)
                let gesture = GestureRegconizer(target: self, action: #selector(buttonOptionDidTouch(_:)))
                gesture.index = $0
                label.addGestureRecognizer(gesture)
                label.isUserInteractionEnabled = true
                return label.padding(.init(x: 16, y: 8), cornerRadius: 12)
            })
        }
    }
    
    var selectedIndex: Int = -1 {
        didSet {
            guard selectedIndex >= 0 && selectedIndex < labels.count else {return}
            for (index, view) in stackView.arrangedSubviews.enumerated() {
                if index != selectedIndex {
                    view.backgroundColor = .clear
                } else {
                    view.backgroundColor = .background4
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
