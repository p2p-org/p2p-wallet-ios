//
// Created by Giang Long Tran on 11.11.21.
//

import Foundation
import UIKit

class KeyView: BEView {
    enum Style {
        case none
        case selected
    }

    var key: String {
        didSet {
            update()
        }
    }

    var index: Int {
        didSet {
            update()
        }
    }

    var hideIndex: Bool {
        didSet {
            update()
        }
    }

    var style: Style {
        didSet {
            update()
        }
    }

    private let textLabel: UILabel = .init(weight: .medium, textColor: .textBlack, textAlignment: .center)

    init(index: Int = 0, key: String, hideIndex: Bool = false, style: Style = .none) {
        self.hideIndex = hideIndex
        self.index = index
        self.key = key
        self.style = style

        super.init(frame: CGRect.zero)
    }

    override func commonInit() {
        super.commonInit()

        layer.borderColor = UIColor.f2f2f7.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 8
        layer.masksToBounds = true

        addSubview(textLabel)
        textLabel.autoPinEdgesToSuperviewEdges()

        update()
    }

    private func update() {
        let textColor = style == .selected ? UIColor.textWhite : UIColor.textBlack
        let indexColor = style == .selected ? UIColor.textWhite : .h8e8e93

        var attrText = NSMutableAttributedString()
        if !hideIndex { attrText = attrText.text("\(index). ", size: 15, weight: .medium, color: indexColor) }
        attrText = attrText.text("\(key)", size: 15, color: textColor)

        textLabel.attributedText = attrText

        switch style {
        case .none:
            backgroundColor = .none
        case .selected:
            backgroundColor = .h5887ff
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
