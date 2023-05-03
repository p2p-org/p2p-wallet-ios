//
// Created by Giang Long Tran on 09.12.21.
//

import BEPureLayout
import Foundation

class WLCard: BECompositionView {
    let child: UIView
    let cornerRadius: CGFloat

    required init(cornerRadius: CGFloat = 12.0, @BEViewBuilder builder: Builder) {
        child = builder().build()
        self.cornerRadius = cornerRadius
        super.init(frame: .zero)
    }

    override func build() -> UIView {
        BEContainer {
            child
                .backgroundColor(color: .contentBackground)
                .border(width: 1, color: .f2f2f7)
                .box(cornerRadius: cornerRadius)
                .lightShadow()
        }
    }
}
