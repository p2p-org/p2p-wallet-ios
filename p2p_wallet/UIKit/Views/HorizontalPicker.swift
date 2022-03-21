//
//  HorizontalPicker.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/12/2020.
//

import Foundation

protocol HorizontalPickerDelegate: AnyObject {
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
            stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            stackView.addArrangedSubviews(labels.enumerated().map {
                let label = UILabel(text: $1)
                label.tag = 1
                let gesture = GestureRegconizer(target: self, action: #selector(buttonOptionDidTouch(_:)))
                gesture.index = $0
                let view = label.padding(.init(x: 16, y: 8), cornerRadius: 12)
                view.addGestureRecognizer(gesture)
                view.isUserInteractionEnabled = true
                return view
            })
        }
    }

    var selectedIndex: Int = -1 {
        didSet {
            guard selectedIndex >= 0, selectedIndex < labels.count else { return }
            for (index, view) in stackView.arrangedSubviews.enumerated() {
                if index != selectedIndex {
                    view.backgroundColor = .clear.onDarkMode(.grayPanel)
                    getLabelAtIndex(index: index)?.textColor = .black.onDarkMode(.h8d8d8d)
                } else {
                    view.backgroundColor = .background4
                    getLabelAtIndex(index: index)?.textColor = .textBlack
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

    private func getLabelAtIndex(index: Int) -> UILabel? {
        guard index < stackView.arrangedSubviews.count else { return nil }
        return stackView.arrangedSubviews[index].viewWithTag(1) as? UILabel
    }
}
