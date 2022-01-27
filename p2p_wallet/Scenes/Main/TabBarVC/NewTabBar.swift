//
// Created by Giang Long Tran on 18.11.21.
//

import Foundation
import BEPureLayout

class NewTabBar: BEView {
    lazy var stackView = UIStackView(
        axis: .horizontal,
        spacing: 10, 
        alignment: .center, 
        distribution: .equalSpacing
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
