//
// Created by Giang Long Tran on 18.11.21.
//

import BEPureLayout
import Foundation

class NewTabBar: BEView {
    lazy var stackView = UIStackView(
        axis: .horizontal,
        alignment: .fill,
        distribution: .fillEqually
    )

    override func commonInit() {
        super.commonInit()
        layout()
    }

    func layout() {
        backgroundColor = .background

        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewSafeArea()

        let separator = BEView.separator(height: 1, color: .separator)
        addSubview(separator)
        separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
    }
}
